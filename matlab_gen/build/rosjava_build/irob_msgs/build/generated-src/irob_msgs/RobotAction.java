package irob_msgs;

public interface RobotAction extends org.ros.internal.message.Message {
  static final java.lang.String _TYPE = "irob_msgs/RobotAction";
  static final java.lang.String _DEFINITION = "# ====== DO NOT MODIFY! AUTOGENERATED FROM AN ACTION DEFINITION ======\n\nirob_msgs/RobotActionGoal action_goal\nirob_msgs/RobotActionResult action_result\nirob_msgs/RobotActionFeedback action_feedback\n";
  static final boolean _IS_SERVICE = false;
  static final boolean _IS_ACTION = true;
  irob_msgs.RobotActionGoal getActionGoal();
  void setActionGoal(irob_msgs.RobotActionGoal value);
  irob_msgs.RobotActionResult getActionResult();
  void setActionResult(irob_msgs.RobotActionResult value);
  irob_msgs.RobotActionFeedback getActionFeedback();
  void setActionFeedback(irob_msgs.RobotActionFeedback value);
}