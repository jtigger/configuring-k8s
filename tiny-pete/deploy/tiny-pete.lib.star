load("@ytt:struct", "struct")

name = "tiny-pete"

valuesAsMap = {
  "name": name,
  "labels": {
    "app.kubernetes.io/app": name
  },
  "service": {
    "name": name,
    "port": 8081,
    "targetPort": 80
  }
}

tiny_pete = struct.encode(valuesAsMap)