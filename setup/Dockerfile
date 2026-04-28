FROM alpine:3.19
RUN apk add --no-cache curl jq
COPY configure.sh step-auth.sh step-repos.sh step-users.sh step-metadata.sh step-tarballs.sh /
RUN chmod +x /configure.sh /step-repos.sh /step-users.sh /step-metadata.sh /step-tarballs.sh
CMD ["/configure.sh"]
