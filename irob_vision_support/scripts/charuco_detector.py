#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import roslib
roslib.load_manifest('irob_vision_support')
import sys
import rospy
import numpy as np
import tf.transformations
import cv2
import cv2.aruco as aruco
from std_msgs.msg import String
from sensor_msgs.msg import Image
from sensor_msgs.msg import CameraInfo
from geometry_msgs.msg import Transform
from geometry_msgs.msg import Vector3
from geometry_msgs.msg import Quaternion
from irob_msgs.msg import Point2D
from irob_msgs.msg import Marker
from irob_msgs.msg import MarkerArray
from cv_bridge import CvBridge, CvBridgeError


class aruco_detector:

  # Constructor
  def __init__(self):
    # Declare aruco stuff
    self.aruco_dict = aruco.Dictionary_get(aruco.DICT_6X6_250)

    self.board = aruco.CharucoBoard_create(3,3,.025,.0125,self.aruco_dict)

    self.parameters =  aruco.DetectorParameters_create()

    self.image_pub = rospy.Publisher("image_markers",Image, queue_size=10)
    self.marker_pub = rospy.Publisher("markers",MarkerArray, queue_size=10)
    self.tr_pub = rospy.Publisher("transform",Transform, queue_size=10)
    self.bridge = CvBridge()
    self.image_sub = rospy.Subscriber("image_input",Image,self.callback)
    self.camera_info_read = False
    self.camera_info_sub = rospy.Subscriber("camera_info",CameraInfo,self.camera_info_callback)



  # Callback for image topic
  def callback(self,data):
    try:
      cv_image = self.bridge.imgmsg_to_cv2(data, "bgr8")
    except CvBridgeError as e:
      print(e)

    (rows,cols,channels) = cv_image.shape
    tr_msg = Transform()
    if cols > 60 and rows > 60 :
      corners, ids, rejectedImgPoints = aruco.detectMarkers(cv_image, self.aruco_dict, parameters=self.parameters)
      #print("aruco")
      #print(corners)

      if len(corners)>0:
        retval, charucoCorners, charucoIds = aruco.interpolateCornersCharuco(corners, ids, cv_image, self.board)
        #print(diamondCorners)
        img = aruco.drawDetectedCornersCharuco(cv_image, charucoCorners)
        if self.camera_info_read and (not charucoCorners is None):
          retval, rvec, tvec=aruco.estimatePoseCharucoBoard(charucoCorners, charucoIds, self.board, self.camera_matrix, self.dist_coeffs	)
          #print(retval)
          if  not rvec is None:
            img = aruco.drawAxis( img, self.camera_matrix, self.dist_coeffs, rvec, tvec, 0.1	)

            rmat, jacobian = cv2.Rodrigues(rvec)
            rmat  = np.append(rmat, [[0,0,0]],0)
            rmat = np.append(rmat, [[0],[0],[0],[1]],1)

            rquat = tf.transformations.quaternion_from_matrix(rmat)

            tr_msg = Transform(Vector3(*tvec), Quaternion(*rquat))

      marker_msg = MarkerArray()
      marker_msg.header = data.header
      marker_msg.markers = []
      #print(corners)
      if not ids is None:
        if len(ids) != 0:
          for i in range(len(ids)):
            marker_msg.markers.append(Marker())
            marker_msg.markers[i].id = int(ids[i])
            marker_msg.markers[i].corners = []
            for j in range((corners[i]).shape[1]):
              marker_msg.markers[i].corners.append(Point2D())
              marker_msg.markers[i].corners[j].x = corners[i][0,j,0]
              marker_msg.markers[i].corners[j].y = corners[i][0,j,1]

    #cv2.imshow("Image window", cv_image)
    #cv2.waitKey(3)

    try:
      self.image_pub.publish(self.bridge.cv2_to_imgmsg(cv_image, "bgr8"))
      self.marker_pub.publish(marker_msg)
      if not tr_msg.translation is None:
        self.tr_pub.publish(tr_msg)
    except CvBridgeError as e:
      print(e)


  # Callback for image topic
  def camera_info_callback(self,data):
    if not self.camera_info_read:
      K = np.asarray(data.K)
      self.camera_matrix = K.reshape(3,3)
      self.dist_coeffs = K = np.asarray(data.D)
      self.camera_info_read = True
      print("Camera info read.")



# Main function
def main(args):
  print("Node started")
  #help(cv2.aruco)

  detector = aruco_detector()
  rospy.init_node('aruco_detector', anonymous=True)
  try:
    rospy.spin()
  except KeyboardInterrupt:
    print("Shutting down")
  cv2.destroyAllWindows()

if __name__ == '__main__':
    main(sys.argv)

