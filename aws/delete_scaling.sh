#!/bin/bash

# Force AutoScaling Group to Delete
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name WEB-ASG --force-delete
