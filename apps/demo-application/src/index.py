from flask import Flask, request
from flask import jsonify

app = Flask(__name__)

@app.route("/_health", methods=["GET"])
def getTotal(bid):
    data = {"response":"OK"}
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
