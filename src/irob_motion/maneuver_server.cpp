/*
 *  maneuver_server.cpp
 *
 *	Author(s): Tamas D. Nagy
 *	Created on: 2017-07-18
 *  
 */

#include "irob_motion/maneuver_server.hpp"

using namespace ias;


ManeuverServer::ManeuverServer(ros::NodeHandle nh, 
	std::vector<std::string> arm_names): 
			nh(nh),
			dissect_as(nh, "dissect", boost::bind(
				&ManeuverServer::dissectActionCB, this, _1), false),
			grasp_as(nh, "grasp", boost::bind(
				&ManeuverServer::graspActionCB, this, _1), false)
{
	
	for(std::vector<std::string>::size_type i = 0; i != arm_names.size(); i++) {
		GestureClient gesture_client(nh, arm_names[i]);
   		arms.push_back(gesture_client);
	}
	
	// Subscribe and advertise topics
	
	subscribeTopics();
    advertiseTopics();
    startActionServers();
}

ManeuverServer::~ManeuverServer()
{
	// TODO Auto-generated destructor stub
}

/*
 * Callbacks
 */
void ManeuverServer::dissectActionCB(
		const irob_autosurg::DissectGoalConstPtr &goal)
{
	// TODO open-close stuff
    bool success = false;
    bool preempted = false;
    ros::Rate loop_rate(0.2);

    irob_autosurg::DissectFeedback feedback;
    irob_autosurg::DissectResult result;
    
    int arm_idx = findArmIdx(goal -> arm_name);
    if (arm_idx < 0)
    	throw std::runtime_error(
			"Arm with the given name not found");
    
    // Close tool
    arms[arm_idx].closeTool(goal->closed_angle);
    while(!arms[arm_idx].isCloseToolDone() && !preempted)
    {
    	// Check that preempt has not been requested by the client
      	if (dissect_as.isPreemptRequested() || !ros::ok())
      	{
        	ROS_INFO_STREAM("Dissect: Preempted");
        	// Set the action state to preempted
        	dissect_as.setPreempted();
        	success = false;
        	preempted = true;
        	break;
      	}
		
		// TODO this can be determined by the details received 
		// in the arm's doneCB
  		loop_rate.sleep();
  		
  		// TODO send feedback
    }
    
    // Go to pos
    arms[arm_idx].goTo(Pose(goal->pose, goal->closed_angle));
    while(!arms[arm_idx].isGoToDone() && !preempted)
    {
    	// Check that preempt has not been requested by the client
      	if (dissect_as.isPreemptRequested() || !ros::ok())
      	{
			ROS_INFO_STREAM("Dissect: Preempted");
        	// Set the action state to preempted
        	dissect_as.setPreempted();
        	success = false;
        	preempted = true;
        	break;
      	}
		
		// TODO this can be determined by the details received 
		// in the arm's doneCB
  		loop_rate.sleep();
  		// TODO send feedback
    }
    
    // penetrate
    arms[arm_idx].penetrate(goal->depth);
    while(!arms[arm_idx].isPenetrateDone()&& !preempted)
    {
    	// Check that preempt has not been requested by the client
      	if (dissect_as.isPreemptRequested() || !ros::ok())
      	{
        	ROS_INFO_STREAM("Dissect: Preempted");
        	// Set the action state to preempted
        	dissect_as.setPreempted();
        	success = false;
        	preempted = true;
        	break;
      	}
		
		// TODO this can be determined by the details received 
		// in the arm's doneCB
  		loop_rate.sleep();
  		// TODO send feedback
    }
    
    // Open tool
    arms[arm_idx].openTool(goal->open_angle);
    while(!arms[arm_idx].isOpenToolDone()&& !preempted)
    {
    	// Check that preempt has not been requested by the client
      	if (dissect_as.isPreemptRequested() || !ros::ok())
      	{
        	ROS_INFO_STREAM("Dissect: Preempted");
        	// Set the action state to preempted
        	dissect_as.setPreempted();
        	success = false;
        	preempted = true;
        	break;
      	}
		
		// TODO this can be determined by the details received 
		// in the arm's doneCB
  		loop_rate.sleep();
  		// TODO send feedback
    }
    
    // penetrate TODO pull action
    arms[arm_idx].penetrate(-(goal->depth));
    while(!arms[arm_idx].isPenetrateDone()&& !preempted)
    {
    	// Check that preempt has not been requested by the client
      	if (dissect_as.isPreemptRequested() || !ros::ok())
      	{
        	ROS_INFO_STREAM("Dissect: Preempted");
        	// Set the action state to preempted
        	dissect_as.setPreempted();
        	success = false;
        	preempted = true;
        	break;
      	}
		
		// TODO this can be determined by the details received 
		// in the arm's doneCB
  		loop_rate.sleep();
  		// TODO send feedback
    }


    if(success)
    {
      	ROS_INFO_STREAM("Dissection succeeded");
		result.info = "Dissection succeeded";
      	// set the action state to succeeded
      	dissect_as.setSucceeded(result);
    }
    
}
  
void ManeuverServer::graspActionCB(
		const irob_autosurg::GraspGoalConstPtr &goal)
{
    ROS_INFO_STREAM("Grasping not implemented yet");
    
    bool success = false;
    bool preempted = false;
    ros::Rate loop_rate(0.2);

    irob_autosurg::GraspFeedback feedback;
    irob_autosurg::GraspResult result;
    
    int arm_idx = findArmIdx(goal -> arm_name);
    
    // TODO not implemented
    
    grasp_as.setSucceeded(result);
}
  
  
void ManeuverServer::subscribeTopics() 
{

}

void ManeuverServer::advertiseTopics() 
{

}

void ManeuverServer::startActionServers() 
{
	dissect_as.start();
	grasp_as.start();
}

int ManeuverServer::findArmIdx(std::string arm_name)
{
	int idx = -1;
	for(std::vector<GestureClient>::size_type i = 0; i != arms.size(); i++) {
		if (arm_name.compare(arms[i].getName()) == 0) {
			idx = i;
			break;
		}
	}
	return idx;
}



