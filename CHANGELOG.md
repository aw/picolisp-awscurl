# Changelog

## 0.7.0 (2018-07-13)

  * Replace (++ L) with (pop 'L) for backward compat with older PicoLisp
  * Add unit tests for awscurl library. #2
  * Add Travis-CI automated testing

## 0.6.0 (2018-06-19)

  * Handle file uploads by accepting '--data @filename' parameter. #4

## 0.5.0 (2018-06-18)

  * Trim leading/trailing spaces from settings in credentials file. #5 (credit: @bl8dd3r)

## 0.4.0 (2018-06-18)

  * Ensure the timezone specified is UTC. #3 (credit: @bl8dd3r)

## 0.3.0 (2018-06-18)

  * Don't ignore the temporary credentials in session token (credit: @patrixl)
  * Allow `AWS_SESSION_TOKEN` environment variable

## 0.2.0 (2018-06-18)

  * First release
