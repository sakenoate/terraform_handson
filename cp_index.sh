BUCKETNAME="my-website-bucket-569313629397"
docker run --rm -it -v ~/.aws:/root/.aws -v $(pwd):/aws amazon/aws-cli --profile cloudformation s3 sync ./test/cloudtech-reservation-web s3://${BUCKETNAME} --exclude "documents/*" --exclude ".git/*"
