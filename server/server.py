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
                "content" : ['h', 'i', ' ', '你', '好', '啊']
            },
            {
                "name" : "Puppy",
                "streaming" : True,
                "content" : ['H', 'i', ' ', 't', 'h', 'e', 'r', 'e', '!', ' ', 'I', "'", 'm', ' ', 'L', 'L', 'a', 'M', 'A', ',', ' ', 'a', 'n', ' ', 'A', 'I', ' ', 'a', 's', 's', 'i', 's', 't', 'a', 'n', 't', ' ', 'd', 'e', 'v', 'e', 'l', 'o', 'p', 'e', 'd', ' ', 'b', 'y', ' ', 'M', 'e', 't', 'a', ' ', 'A', 'I', ' ', 't', 'h', 'a', 't', ' ', 'c', 'a', 'n', ' ', 'u', 'n', 'd', 'e', 'r', 's', 't', 'a', 'n', 'd', ' ', 'a', 'n', 'd', ' ', 'r', 'e', 's', 'p', 'o', 'n', 'd', ' ', 't', 'o', ' ', 'h', 'u', 'm', 'a', 'n', ' ', 'i', 'n', 'p', 'u', 't', ' ', 'i', 'n', ' ', 'a', ' ', 'c', 'o', 'n', 'v', 'e', 'r', 's', 'a', 't', 'i', 'o', 'n', 'a', 'l', ' ', 'm', 'a', 'n', 'n', 'e', 'r', '.', ' ', 'I', "'", 'm', ' ', 'n', 'o', 't', ' ', 'a', ' ', 'h', 'u', 'm', 'a', 'n', ',', ' ', 'b', 'u', 't', ' ', 'a', ' ', 'c', 'o', 'm', 'p', 'u', 't', 'e', 'r', ' ', 'p', 'r', 'o', 'g', 'r', 'a', 'm', ' ', 'd', 'e', 's', 'i', 'g', 'n', 'e', 'd', ' ', 't', 'o', ' ', 's', 'i', 'm', 'u', 'l', 'a', 't', 'e', ' ', 'c', 'o', 'n', 'v', 'e', 'r', 's', 'a', 't', 'i', 'o', 'n', ' ', 'a', 'n', 'd', ' ', 'a', 'n', 's', 'w', 'e', 'r', ' ', 'q', 'u', 'e', 's', 't', 'i', 'o', 'n', 's', ' ', 't', 'o', ' ', 't', 'h', 'e', ' ', 'b', 'e', 's', 't', ' ', 'o', 'f', ' ', 'm', 'y', ' ', 'a', 'b', 'i', 'l', 'i', 't', 'i', 'e', 's', '.', ' ', 'I', "'", 'm', ' ', 'h', 'e', 'r', 'e', ' ', 't', 'o', ' ', 'h', 'e', 'l', 'p', ' ', 'a', 'n', 'd', ' ', 'c', 'h', 'a', 't', ' ', 'w', 'i', 't', 'h', ' ', 'y', 'o', 'u', ',', ' ', 's', 'o', ' ', 'f', 'e', 'e', 'l', ' ', 'f', 'r', 'e', 'e', ' ', 't', 'o', ' ', 'a', 's', 'k', ' ', 'm', 'e', ' ', 'a', 'n', 'y', 't', 'h', 'i', 'n', 'g', '!']
            }
        ]
    }
    # return jsonify(json.dumps(msg))
    return jsonify(msg)

    # return str(msg)


if __name__ == '__main__':
    app.run(port=5001, debug=True)  # 运行服务，并监听5000端口

