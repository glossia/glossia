# ID: pepicrft/deno:alpine-git-1.36.1
FROM denoland/deno:alpine-1.36.1
# docker build . -t pepicrft/deno:alpine-git-1.36.1 && docker push pepicrft/deno:alpine-git-1.36.1

# Make sure apk registry is up to date
RUN apk update

# Install Git
RUN apk add --no-cache git
RUN git config --global user.name "Glossia"
RUN git config --global user.email "git@glossia.ai"

# Set the Deno executable as the entrypoint 
ENTRYPOINT ["deno"]