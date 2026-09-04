#!/bin/bash
pnpm install
cd apps/mobile/android
./gradlew clean
cd ../../..
pnpm --filter mobile run android
