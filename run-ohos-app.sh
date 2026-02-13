#!/bin/bash

BUNDLE_ID="org.oniroproject.ionicohos"

cd native-template

hvigorw assembleHap --mode module -p product=default -p module=entry -p buildMode=debug --stacktrace --no-parallel --no-daemon

hdc install entry/build/default/outputs/default/entry-default-signed.hap
hdc shell hilog -r
hdc shell aa start -a EntryAbility -b "$BUNDLE_ID"
pid=$(timeout 0.5 hdc track-jpid | awk -v id="$BUNDLE_ID" '$2==id {print $1}')
echo "app running PID: $pid"
hdc shell hilog -P "$pid"