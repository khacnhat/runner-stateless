FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Inside runner.rb I chown files to the sandbox user/group
# I'm setting runner's uid:gid to the _same_ as the sandbox user
# (inside the container runner runs) otherwise the chown gets
# a permission denied error.
# Possible that with this change I don't need to do the chown at all.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

USER root

RUN addgroup -g 51966 runner

RUN adduser \
  -G runner `# group`       \
  -D        `# no password` \
  -H        `# no home dir` \
  -u 41966  `# user-id`     \
  runner    `# user-name`

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# On DockerToolbox for Mac, on the default VM
# /etc/group has docker group with gid=100
# This means /var/run/docker.sock has a gid=100
# On an Alpine image (such as this), /etc/group
# has a group called users with gid=100
# So if I make my user a member of this group, then
# my user will have access to /var/run/docker.sock
# Obvious problem with this approach is that the docker
# group has different gids on different OS's.
# For example, on Ubuntu 16.04 (in Google Computer Engine)
# /etc/group has a docker group with a gid of 999
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RUN adduser runner users


ARG HOME=/app
COPY . ${HOME}

ARG SHA
RUN echo ${SHA} > ${HOME}/sha.txt

USER runner
EXPOSE 4597
CMD [ "./up.sh" ]
