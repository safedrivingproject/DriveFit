      // if (widget.accelerometerOn) {
      //   liveAccelList.add(globals.resultantAccel);
      //   if (liveAccelList.length > 10) {
      //     liveAccelList.removeAt(0);
      //   }
      //   maxAccel = liveAccelList.fold<double>(0, max);
      //   if (maxAccel > maxAccelThreshold) {
      //     accelMovingCounter++;
      //   } else {
      //     accelMovingCounter = 0;
      //   }
      //   if (accelMovingCounter > 20) {
      //     if (mounted) {
      //       setState(() {
      //         carMoving = true;
      //       });
      //     }
      //   }
      //   if (maxAccel <= maxAccelThreshold) {
      //     accelStoppedCounter++;
      //   } else {
      //     accelStoppedCounter = 0;
      //   }
      //   if (accelStoppedCounter > 20) {
      //     if (mounted) {
      //       setState(() {
      //         carMoving = false;
      //       });
      //     }
      //   }
      // } else {
      // carMoving = true;
      // }