var express = require('express')
var app = express()

app.get('/', (req, res) => {
  console.log(req.protocol + " " + req.method + " " + req.path)
  for (var key in req.headers) {
    console.log(`${key}: ${req.headers[key]}`)
  }
  console.log("")
  res.send('Ok')
})

app.listen(80)
