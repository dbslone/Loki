Loki
=======

A Heroku based distributed load testing tool.

Configuration variables should be set as follows:

  - `BUILDPACK_URL`: Specify the Heroku Ruby buildpack (`"https://github.com/heroku/heroku-buildpack-ruby"`)
  - `CHANNEL`: Name of PubNub channel for broadcasting
  - `WORKERS`: The number of workers processes (default: `12`)
  - `LENGTH` The number of times each worker will hit each endpoint; use `0` to run continuously (default: `10000`)

Then use the following command in the `Procfile`:

    program: ruby ./killtheweb.rb start $CHANNEL --workers=$WORKERS --length=$LENGTH

Each dyno should spin up `$WORKERS` to broadcast messages. From my testing on 1x dyno, each worker will generate about 500 RPM, and 12 should safely fit on a 1x dyno. I have not tested on 2x or Px dynos, so YMMV.

Example:

    heroku config:set \
      BUILDPACK_URL="https://github.com/heroku/heroku-buildpack-ruby" \
      CHANNEL="into-the-wild" \
      WORKERS=36 \
      LENGTH=10000 \
      PUBLISH="" \
      SUBSCRIBE=""

    heroku scale program=5

This will assault the three action endpoints with 60 concurrent worker. Each worker will access the URLs given 10000 times, and then quietly die. You'll need to scale down and up or restart the dynos to rerun the test.
