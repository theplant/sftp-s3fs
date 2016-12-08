# Supported tags and respective `Dockerfile` links

- [`debian-jessie`, `debian`, `latest` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/master/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp.svg)](http://microbadger.com/images/atmoz/sftp "Get your own image badge on microbadger.com")
- [`alpine-3.4`, `alpine` (*Dockerfile*)](https://github.com/atmoz/sftp/blob/alpine/Dockerfile) [![](https://images.microbadger.com/badges/image/atmoz/sftp:alpine.svg)](http://microbadger.com/images/atmoz/sftp "Get your own image badge on microbadger.com")

# Securely share your files with S3 filesystem baked-in with s3fs_fuse

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH).
This is an automated build linked with the [debian](https://hub.docker.com/_/debian/) and [alpine](https://hub.docker.com/_/alpine/) repositories.

# Usage

- Define users as command arguments, STDIN or mounted in `/etc/sftp-users.conf`
  (syntax: `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]]...`).
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Add directory names at the end, if you want to create them and/or set user
    ownership. Perfect when you just want a fast way to upload something without
    mounting any directories, or you want to make sure a directory is owned by
    a user (chown -R).
- Mount volumes in user's home directory. Not supported with s3fs_fuse addition
  - The users are chrooted to their home directory, so you must mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**).
- s3fs is currently only supported with a single user-dir. 
  Adding additional mounts for multiple users should be simple, but not in my original use-case.
  last-in wins currently

# Examples


## Simplest docker run example

```
docker run -e bucket_name=S3_BUCKET_NAME[:/OPTIONAL_SUBDIR] -e ami_id=REPLACE_WITH_AMI_ID -e ami_secret=REPLACE_WITH_AMI_SECRET --security-opt apparmor:unconfined --cap-add mknod --cap-add sys_admin --device=/dev/fuse -p 21:22 -d chessracer/sftp-s3fs testuser:password:1000:1000:user_subdir

```
User "testuser" with password "testpass" can login with sftp and upload files to a folder called "s3_bucket". Files uploaded this way are synced to S3 with the named S3_BUCKET_NAME.
The provide ami_id and ami_secret must have roles to write to that s3 bucket

## Example to connect to a locally-running instance on the default docker IP:
```
sftp -P 21 testuser@172.17.0.1:user_subdir
sftp> put somefile
sftp> ls
somefile
```

### Using Docker Compose:

```
TODO
```

## Example Login: connect to a locally-running instance on the default docker IP:
```
sftp -P 21 testuser@172.17.0.1:user_subdir
sftp> put somefile
sftp> ls
somefile
```

## Store users in config - NOTE: Multiple users not yet supported for s3fs (last-in wins for s3fs mount)

```
docker run \
    -v /host/users.conf:/etc/sftp-users.conf:ro \
    -v /host/share:/home/foo/share \
    -v /host/documents:/home/foo/documents \
    -v /host/http:/home/bar/http \
    -p 2222:22 -d atmoz/sftp
```

/host/users.conf:

```
foo:123:1001
bar:abc:1002
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d atmoz/sftp \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e:1001'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Using SSH key (and no password)

Mount all public keys in the user's `.ssh/keys/` directory. All keys are automatically
appended to `.ssh/authorized_keys`.

```
docker run \
    -v /host/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v /host/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d atmoz/sftp \
    foo::1001
```

## Execute custom scripts or applications

Put your programs in `/etc/sftp.d/` and it will automatically run when the container starts.
See next section for an example.

## Bindmount dirs from another location

If you are using `--volumes-from` or just want to make a custom directory
available in user's home directory, you can add a script to `/etc/sftp.d/` that
bindmounts after container starts.

```
#!/bin/bash
# File mounted as: /etc/sftp.d/bindmount.sh
# Just an example (make your own)

function bindmount() {
    if [ -d "$1" ]; then
        mkdir -p "$2"
    fi
    mount --bind $3 "$1" "$2"
}

# Remember permissions, you may have to fix them:
# chown -R :users /data/common

bindmount /data/admin-tools /home/admin/tools
bindmount /data/common /home/dave/common
bindmount /data/common /home/peter/common
bindmount /data/docs /home/peter/docs --read-only
```
