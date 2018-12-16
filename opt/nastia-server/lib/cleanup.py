#!/usr/bin/python

#
# Remove old incremental backups
# Emulating the behavior of Apple Time Machine
#

import sys
import re
import shutil
import os
from datetime import datetime
from os import listdir
from os import popen

# Current directory where this script is located
DIR = os.path.dirname(os.path.abspath(__file__))

# Minimum allowed free backup disk space in percent
FREE_PERCENT = 5

#print 'Number of arguments:', len(sys.argv), 'arguments.'
#print 'Argument List:', str(sys.argv)

# Check for correct number of arguments
if len(sys.argv) < 1:
  print "usage: " + sys.argv[0] + " PATH [--dry-run]"
  sys.exit()

# Parse arguments
backupPath = sys.argv[1]
dirList = []

print " "
print "cleaning-up backups folder:", backupPath, "..."

# Check if dry run
dryRun = 0
if len(sys.argv) == 3:
  if sys.argv[2] == "--dry-run":
    dryRun = 1
    print "dry run"



# Print info log message
def infoLog ( text ):
  print text
  popen( DIR + "/infoLog.sh \"" + text + "\" 'cleanup' '' 'c'" )


# Print warning log message
def warningLog ( text ):
  print "[WARNING] " + text
  popen( DIR + "/warningLog.sh \"" + text + "\" 'cleanup' '' 'c'" )


# Print error log message
def errorLog ( text ):
  print "[ERROR] " + text
  popen( DIR + "/errorLog.sh \"" + text + "\" 'cleanup' '' 'c'" )



# Collect the backup folders
for d in listdir(backupPath):
  match = re.search("^\d{4}-\d{2}-\d{2}-\d{6}$",d)
  if match:
    dirList.append(d)

# Sort them in alphabetical order
dirList.sort()

# Initialize timestamps
today = datetime.strptime(dirList[len(dirList)-1],"%Y-%m-%d-%H%M%S")
today = today.replace(second = 0) # Round-down to the nearest minute
lastT = datetime(1970,01,01)

# Iterate over backup directories and delete according to rules
for dir in dirList:
  t = datetime.strptime(dir,"%Y-%m-%d-%H%M%S")
  t = t.replace(second = 0) # Round-down to the nearest minute
  age = today - t
  delta = t - lastT
  fullPath=backupPath + "/" + dir
  if dryRun:
    print dir + ":"
    print "    time  = " + str(t.year) + "-" + str(t.month) + "-" + str(t.day) + " " + str(t.hour) + ":" + str(t.minute) + ":" + str(t.second)
    print "    age   = " + str(age.days) + "d " + str(age.seconds) + "s"
    print "    delta = " + str(delta.days) + "d " + str(delta.seconds) + "s"
  if age.days > 2 and delta.days < 1:
    if dryRun == 0: shutil.rmtree(fullPath)
    infoLog( "removed " + fullPath )
    continue
  if age.days > 14 and delta.days < 7:
    if dryRun == 0: shutil.rmtree(fullPath)
    infoLog( "removed " + fullPath )
    continue
  if age.days > 56 and delta.days < 28:
    if dryRun == 0: shutil.rmtree(fullPath)
    infoLog( "removed " + fullPath )
    continue
  lastT = t

# Check remaining disk space
dfCmd = "df --block-size=1G " + backupPath + " | tail -1 | awk '{print $4}'"
dfCmdTotal = "df --block-size=1G " + backupPath + " | tail -1 | awk '{print $2}'"
freeSpace = int(popen(dfCmd).read())
totalSpace = int(popen(dfCmdTotal).read())
freePercent = freeSpace * 100 / totalSpace
i = 0
# Free-up disk space by deleting oldest backups
while freePercent < FREE_PERCENT:
  if i == 0:
    print "available disk space: " + str(freeSpace) + " GB (" + str(freePercent) + "%)"
    print "deleting old backups to free-up disk space:"
  fullPath = backupPath + "/" + dirList[i]
  if dryRun == 0: 
    shutil.rmtree(fullPath)
    freeSpace = int(popen(dfCmd).read()) 
    freePercent = freeSpace * 100 / totalSpace
  else:
    freeSpace += 5
    freePercent = freeSpace * 100 / totalSpace      
  warningLog( "removed oldest backup " + fullPath )
  i = i + 1
  if i >= 5: break
  if i >= (len(dirList) - 1 ): break

print "available disk space: " + str(freeSpace) + " GB (" + str(freePercent) + "%)"

print "done"
