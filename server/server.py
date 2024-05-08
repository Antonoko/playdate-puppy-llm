from flask import Flask, request, jsonify
from flask_cors import CORS

import json

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "https://pdportal.net"}})

@app.route('/mypostendpoint', methods=['POST'])
def mypostendpoint():
    data = request.get_json()  # 当你发送JSON数据时，你可以使用这种方式获取数据
    print(data)  # 打印接收到的数据
    # return jsonify({"message": "i got your data", "your_data": data})  # 返回一个响应
    msg = {
        "msglist": [
            {
                "name" : "You",
                "streaming" : False,
                "content" : ["f","u"]
            },
            {
                "name" : "Puppy",
                "streaming" : True,
                "content" : ["啊","啊","啊","\n","啊","啊","啊","啊","啊","啊","啊","啊","啊","啊","啊","草"]
            }
        ]
    }
    # return jsonify(json.dumps(msg))
    return jsonify(msg)

    # return str(msg)


if __name__ == '__main__':
    app.run(port=5001, debug=True)  # 运行服务，并监听5000端口

