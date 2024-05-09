# Puppy

This is an LLM interface that pays homage to rabbit r1 on Playdate.

> [!WARNING]
> The project is in the early and experimental stages and may be very unstable and unavailable.

## how to run
### Desktop side setting
1. Download code: via `Code` - `Download ZIP`
1. Install [python](https://www.python.org/downloads/release/python-3119/)
2. Navigate to the `server` directory
3. Configure your LLM api: Create `config.json` in `server` directory with the following content (openai compatible format, You can find it in the development documents of various LLM provider.)
```json
{
    "open_ai_base_url" : "https://YourLLMServiceAPIBaseUrl",
    "open_ai_api_key" : "your api key",
    "open_ai_modelname" : "api model name, like llama3-70b-8192"
}
```
4. Install python dependencies `pip install -r requirements.txt`
5. Run `python server.py`, start the service (By default it will run at http://127.0.0.1:5001/llmproxy)

### Playdate setting
1. Download pdx in release and sideload it to your playdate
2. Open puppy on playdate
3. Connect playdate to the computer via USB, open [https://pdportal.net/](https://pdportal.net/) on the desktop browser, and click connect (make sure the playdate emulator is not opened, etc. to occupy its USB port program of)
4. If everything goes well, communication should be possible!

## how to use
- hold down button and rotate playdate to change modes

## todo
- [ ] make server_address could be change on app rather than hard-coding it into the program
- [ ] fix welcome msg blink

## Big thanks to
- [pd-usb](https://github.com/cranksters/pd-usb)
- [pdportal](https://github.com/strawdynamics/pdportal)
- [playdate-chinese-IME](https://github.com/Antonoko/playdate-chinese-IME)