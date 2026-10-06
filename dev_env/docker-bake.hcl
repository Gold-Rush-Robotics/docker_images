variable "IMAGE" {
    default = "ghcr.io/gold-rush-robotics/dev_env"
}

variable "VERSION" {
    default = "9"
}

target "dev_env" {
    context    = "."
    dockerfile = "Dockerfile"

    platforms = [
        "linux/amd64",
        "linux/arm64"
    ]

    tags = [
        "${IMAGE}:${VERSION}"
    ]

    provenance = false
}