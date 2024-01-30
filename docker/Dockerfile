# Runtime image
ARG LITELLM_RUNTIME_IMAGE=python:3.11-alpine

# Runtime stage
FROM $LITELLM_RUNTIME_IMAGE as runtime

RUN pip install 'litellm[proxy]'

EXPOSE 8000/tcp

# Set your entrypoint and command
ENTRYPOINT ["litellm"]
CMD ["--port", "8000"]