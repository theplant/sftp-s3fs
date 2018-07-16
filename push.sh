docker build -t registry.theplant-dev.com/public/sftp-s3fs:$(cat VERSION) .
docker push registry.theplant-dev.com/public/sftp-s3fs:$(cat VERSION)
