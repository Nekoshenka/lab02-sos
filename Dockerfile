FROM python:3.11-alpine AS builder

RUN apk add --no-cache gcc musl-dev python3-dev

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-alpine

RUN apk add --no-cache curl

ARG LAB_LOGIN
ARG LAB_TOKEN

LABEL org.lab.login=$LAB_LOGIN
LABEL org.lab.token=$LAB_TOKEN

RUN addgroup -S appuser && adduser -S appuser -G appuser

RUN mkdir -p /app /var/log/app && \
    chown appuser:appuser /app /var/log/app && \
    chmod 755 /app && \
    chmod 775 /var/log/app

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=builder /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=builder /usr/local/bin/python /usr/local/bin/python

RUN ln -sf /usr/local/bin/python3 /usr/local/bin/python

COPY --chown=appuser:appuser app/ ./

USER appuser

ENV ROCKET_SIZE=Medium
ENV LAB_LOGIN=$LAB_LOGIN
ENV LAB_TOKEN=$LAB_TOKEN

VOLUME ["/tmp"]

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["python", "app.py"]
