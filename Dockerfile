FROM golang:1.21

WORKDIR /app

COPY . .
RUN if [ ! -f go.mod ]; then go mod init app; fi
RUN go mod tidy

RUN go build -o main .

EXPOSE 8081

CMD ["./main"]