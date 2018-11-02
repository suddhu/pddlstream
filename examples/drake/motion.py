import numpy as np

from examples.drake.utils import get_random_positions, get_joint_limits, set_joint_positions, get_joint_positions, \
    exists_colliding_pair, create_transform, solve_inverse_kinematics
from examples.pybullet.utils.motion.motion_planners.rrt_connect import birrt

DEFAULT_WEIGHT = 1.0
DEFAULT_RESOLUTION = 0.005*np.pi

##################################################


def get_sample_fn(joints):
    return lambda: get_random_positions(joints)


def get_difference_fn(joints):

    def fn(q2, q1):
        assert len(joints) == len(q2)
        assert len(joints) == len(q1)
        # TODO: circular joints
        difference = []
        for joint, value2, value1 in zip(joints, q2, q1):
            #difference.append((value2 - value1) if is_circular(body, joint)
            #                  else circular_difference(value2, value1))
            difference.append(value2 - value1)
        return np.array(difference)
    return fn


def get_distance_fn(joints, weights=None):
    # TODO: custom weights and step sizes
    if weights is None:
        weights = DEFAULT_WEIGHT*np.ones(len(joints))
    difference_fn = get_difference_fn(joints)

    def fn(q1, q2):
        diff = np.array(difference_fn(q2, q1))
        return np.sqrt(np.dot(weights, diff * diff))
    return fn


def get_extend_fn(joints, resolutions=None):
    if resolutions is None:
        resolutions = DEFAULT_RESOLUTION*np.ones(len(joints))
    assert len(joints) == len(resolutions)
    difference_fn = get_difference_fn(joints)

    def fn(q1, q2):
        num_steps = int(np.max(np.abs(np.divide(difference_fn(q2, q1), resolutions)))) + 1
        q = q1
        for i in range(num_steps):
            q = (1. / (num_steps - i)) * np.array(difference_fn(q2, q)) + q
            yield q
            # TODO: wrap these values
    return fn


def within_limits(joint, position):
    lower, upper = get_joint_limits(joint)
    return lower <= position <= upper


def get_collision_fn(mbp, context, joints, collision_pairs=set(), attachments=[]):
    # TODO: collision bodies or collision models?
    # TODO: self-collisions

    def fn(q):
        if any(not within_limits(joint, position) for joint, position in zip(joints, q)):
            return True
        if not collision_pairs:
            return False
        set_joint_positions(joints, context, q)
        for attachment in attachments:
            attachment.assign(context)
        return exists_colliding_pair(mbp, context, collision_pairs)
    return fn

##################################################


def refine_joint_path(joints, waypoints, resolutions=None):
    if resolutions is None:
        resolutions = 0.1*DEFAULT_RESOLUTION*np.ones(len(joints))
    extend_fn = get_extend_fn(joints, resolutions=resolutions)
    refined_path = []
    for q1, q2 in zip(waypoints, waypoints[1:]):
        refined_path.extend(extend_fn(q1, q2))
    return refined_path


def plan_waypoints_joint_motion(mbp, context, joints, waypoints, resolutions=None,
                                collision_pairs=set(), attachments=[]):
    extend_fn = get_extend_fn(joints, resolutions=resolutions)
    collision_fn = get_collision_fn(mbp, context, joints, collision_pairs=collision_pairs,
                                    attachments=attachments)
    start_positions = get_joint_positions(joints, context)
    path = [start_positions]
    for waypoint in waypoints:
        assert len(joints) == len(waypoint)
        for q in extend_fn(path[-1], waypoint):
            if collision_fn(q):
                return None
            path.append(q)
    return path

def plan_joint_motion(mbp, context, joints, end_positions,
                      weights=None, resolutions=None,
                      collision_pairs=set(), attachments=[], **kwargs):
    assert len(joints) == len(end_positions)
    start_positions = get_joint_positions(joints, context)
    return birrt(start_positions, end_positions,
                 distance=get_distance_fn(joints, weights=weights),
                 sample=get_sample_fn(joints),
                 extend=get_extend_fn(joints, resolutions=resolutions),
                 collision=get_collision_fn(mbp, context, joints, collision_pairs=collision_pairs,
                                            attachments=attachments), **kwargs)

##################################################

def get_unit_vector(vec):
    norm = np.linalg.norm(vec)
    if norm == 0.:
        return vec
    return np.array(vec) / norm


def waypoints_from_path(joints, path):
    if len(path) < 2:
        return path
    difference_fn = get_difference_fn(joints)
    waypoints = [path[0]]
    last_conf = path[1]
    last_difference = get_unit_vector(difference_fn(last_conf, waypoints[-1]))
    for i, conf in enumerate(path[2:]):
        if np.linalg.norm(difference_fn(path[i-1], conf)) == 0:
            continue
        difference = get_unit_vector(difference_fn(conf, waypoints[-1]))
        if not np.allclose(last_difference, difference, atol=1e-3, rtol=0):
            waypoints.append(last_conf)
            difference = get_unit_vector(difference_fn(conf, waypoints[-1]))
        last_conf = conf
        last_difference = difference
    waypoints.append(last_conf)
    return waypoints


def interpolate_translation(transform, translation, step_size=0.01):
    distance = np.linalg.norm(translation)
    if distance == 0:
        yield transform
        return
    direction = np.array(translation) / distance
    for t in list(np.arange(0, distance, step_size)) + [distance]:
        yield transform.multiply(create_transform(translation=t * direction))


def plan_workspace_motion(mbp, context, joints, frame, frame_path, initial_guess=None, **kwargs):
    collision_fn = get_collision_fn(mbp, context, joints, **kwargs)
    solution = initial_guess
    waypoints = []
    for frame_pose in frame_path:
        solution = solve_inverse_kinematics(mbp, frame, frame_pose, initial_guess=solution)
        if solution is None:
            return None
        positions = [solution[j.position_start()] for j in joints]
        if collision_fn(positions):
            return None
        waypoints.append(positions)
    return waypoints