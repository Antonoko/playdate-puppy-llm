from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI

import json
import datetime

with open("config.json", "r", encoding="utf-8") as f:
    config = json.load(f)

open_ai_base_url = config["open_ai_base_url"]
open_ai_api_key = config["open_ai_api_key"]
open_ai_modelname = config["open_ai_modelname"]
llm_temperature = 0.8

user_dialog = []
system_msg = {
            "role": "system",
            "content": f"You are a helpful assistance. Your name is Puppy, user communicate with you on a handful device name Playdate. Time now: {datetime.datetime.now()}",
        }

# -----------------------------------------------

def turn_str_to_lst(text):
    lst = []
    for i in text:
        lst.append(i)
    return lst


def request_llm(
    user_last_content
):
    global user_dialog
    msg_user = {"role": "user", "content": user_last_content}

    try:
        client = OpenAI(
            api_key=open_ai_api_key,
            base_url=open_ai_base_url,
        )
        payload_msg = []
        payload_msg.append(system_msg)
        payload_msg.extend(user_dialog)
        payload_msg.append(msg_user)

        completion = client.chat.completions.create(
            model=open_ai_modelname,
            messages=payload_msg,
            temperature=llm_temperature,
        )
    except Exception as e:
        print("---ERROR:")
        print(e)
        return False, "error."

    print(completion.choices[0].message.content)

    res = {"role": "assistant", "content": completion.choices[0].message.content}
    user_dialog.append(msg_user)
    user_dialog.append(res)

    return True, completion.choices[0].message.content


# def format_to_pd(user_dialog=user_dialog):
#     msg_lst = []
#     i = 1
#     for chat_session in user_dialog:
#         append_res = {
#                 "name" : "System",
#                 "streaming" : False,
#                 "content" : turn_str_to_lst("error")
#             }
#         if chat_session["role"] == "user":
#             append_res = {
#                 "name" : "You",
#                 "streaming" : False,
#                 "content" : turn_str_to_lst(chat_session["content"])
#             }
#         elif chat_session["role"] == "assistant":
#             append_res = {
#                 "name" : "Puppy",
#                 "streaming" : True if i == len(user_dialog) else False,
#                 "content" : turn_str_to_lst(chat_session["content"])
#             }
#         msg_lst.append(append_res)
#         i += 1
#     msg = {
#         "msglist": msg_lst
#     }
#     return msg

# -----------------------------------------------

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "https://pdportal.net"}})

@app.route('/llmproxy', methods=['POST'])
def llmproxy():
    global user_dialog

    data_received = request.get_json()
    print(data_received)

    response_pd = {
                    "usermsg": turn_str_to_lst(data_received["data"]["msg"]),
                    "llmmsg": turn_str_to_lst("server error.")
                }

    try:
        if data_received["data"]["new_chat"]:
            user_dialog = []
        
        request_success, request_content = request_llm(data_received["data"]["msg"])
        response_pd = {
                    "usermsg": turn_str_to_lst(data_received["data"]["msg"]),
                    "llmmsg": turn_str_to_lst(request_content)
                }

    except Exception as e:
        print("---ERROR:")
        print(e)

    print(response_pd)
    return json.dumps(response_pd)
    # return jsonify(response_pd)


if __name__ == '__main__':
    app.run(port=5001, debug=True)




"""
{
    "msg" : "hello",
    "new_chat" : false
}
"""
