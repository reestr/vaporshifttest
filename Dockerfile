# ================================
# Build image
# ================================
FROM swift:5.9-rhel-ubi9 as build

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
#COPY ./Package.* ./
#RUN swift package resolve --skip-update \
#        "$([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)"

# Copy entire repo into container
COPY . .

# Build everything, with optimizations
RUN swift build -c release --static-swift-stdlib

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/App" ./

# Copy resources bundled by SPM to staging area
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# Copy any resources from the public directory and views directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM redhat/ubi9-minimal

# Create a vapor user and group with /app as its home directory
#RUN groupadd -g 42 vapor && \
#    useradd -m -r -u 42 -g vapor vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
#COPY --from=build --chown=vapor:vapor /staging /app
COPY --from=build /staging /app

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_ROOT=/usr SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no

# Ensure all further commands run as the vapor user
#USER vapor:vapor

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]