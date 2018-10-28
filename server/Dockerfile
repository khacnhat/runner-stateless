FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Old comment...
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. lib/runner sh files needs to run /usr/bin/docker
# after this, the sh file (running as cyber-dojo user) can do
#     $ sudo -u docker-runner sudo docker run ...
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Ok so I think this was when cyber-dojo was a docker-image monolith
# and ran as a user called cyber-dojo.
# The commands below created a new user called docker-runner
# which the cyber-dojo could sudo as.
# The docker-runner user had rights to the docker binary.
# Now the runner is a separate service it can have its own user
# and that can be granted rights to the docker binary directly...
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Currently getting a failure with
# chown 41966:51966 /tmp/452..324/sandbox
# which is because the user is now the runner user...
# Hmmmmm. Is there a cheat here.
# Could I make the uid of runner the same as the uid of sandbox...?
# This might mean I could drop chmod/chown commands
# as that would be what they get anyway...
# Reasonable approach just to see if docker command actually run...
# That indeed got me further...
# But now getting.
# /var/run/docker.sock: connect: permission denied
#
# Could I make runner be a member of docker group?
# And also sandbox group?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

USER root

# On DockerToolbox for Mac, on the default VM
# /etc/group has docker group with gid=100
# This means /var/run/docker.sock has a gid=100
# On an Alpine image (such as this), /etc/group
# has a group called users with gid=100
# There is also a user called guest that has
# the group users as its primary group.
# So I need to delete the user called guest, and the
# group called users, so that I can create a new group
# with a gid of 100. Then I can make my user
# a member of this group, and after all that,
# my user will have access to /var/run/docker.sock
# Obvious problem with this is that the docker group
# has different gids on different OS's.
# For example, on Ubuntu 16.04 (in Google Computer Engine)
# /etc/group also has a group called users with gid=100
# but its docker group has a gid of 999

RUN deluser guest
RUN delgroup users
RUN addgroup -g 100 docker

RUN adduser \
  -G docker `# group`       \
  -D        `# no password` \
  -H        `# no home dir` \
  -u 41966  `# user-id`     \
  runner    `# user-name`

# I tar-pipe files into the sandbox dir
# These need to be owned by the sandbox user.
# So I need to chmod the files before tar-piping them.
# And I think I also need to run the tar command as root.
# This all appears to work, but everything is running _much_ slower.

RUN addgroup -g 51966 runner
RUN adduser runner runner

# there is no sudo command in default Alpine
RUN  apk --update add sudo

ARG  DOCKER_BINARY=/usr/local/bin/docker

ARG  GETS_DOCKER_SUDO=runner
ARG  SUDO_FILE=/etc/sudoers.d/${GETS_DOCKER_SUDO}
# runner user, on all hosts, without a password, can sudo /usr/local/bin/docker
RUN echo "${GETS_DOCKER_SUDO}  ALL=NOPASSWD: ${DOCKER_BINARY} *" >> ${SUDO_FILE}


# -----------------------------------------
# DEAD
# -D=no password, -H=no home directory
#RUN  adduser -D -H ${GETS_DOCKER_SUDO}
#ARG  NEEDS_DOCKER_SUDO=cyber-dojo
# cyber-dojo, on all hosts, can sudo -u docker-runner, without a password
#RUN  echo "${NEEDS_DOCKER_SUDO} ALL=(${GETS_DOCKER_SUDO}) NOPASSWD: ALL" >  ${SUDO_FILE}
# -----------------------------------------


ARG HOME=/app
COPY . ${HOME}

ARG SHA
RUN echo ${SHA} > ${HOME}/sha.txt

USER runner
EXPOSE 4597
CMD [ "./up.sh" ]
