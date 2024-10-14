from flask import Flask, request, jsonify
import requests
from DrissionPage import Chromium, ChromiumOptions
import time
import os

app = Flask(__name__)


def initialize_browser(proxy, user_agent):
    co = ChromiumOptions()
    co.auto_port()

    # 从环境变量获取浏览器路径，默认值为常见路径
    browser_path = os.getenv('BROWSER_PATH', '/usr/bin/google-chrome')
    co.set_browser_path(browser_path)

    if proxy:
        co.set_proxy(proxy)
    else:
        raise ValueError("Proxy未提供。")

    if user_agent:
        co.set_user_agent(user_agent=user_agent)
    else:
        # 默认的User-Agent，如果未提供
        co.set_user_agent(user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                                     'AppleWebKit/537.36 (KHTML, like Gecko) '
                                     'Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0')

    co.headless(True)
    co.set_argument('--no-sandbox')
    co.set_argument('--window-size=800,600')
    co.incognito(on_off=True)

    browser = Chromium(addr_or_opts=co)
    tab = browser.latest_tab
    return browser, tab


def get_cf_clearance(tab, url, max_retries=3):
    for attempt in range(1, max_retries + 1):
        try:
            tab.get(url)

            # 获取并操作元素
            rXOa8_ele = tab.ele('#:rXOa8')
            div_elements = rXOa8_ele.eles('tag:div')
            if len(div_elements) < 2:
                raise Exception("未找到足够的div元素。")

            sr_ele = div_elements[1].shadow_root
            iframe = sr_ele.get_frame(1)
            body = iframe.ele('tag:body').shadow_root

            try:
                # 尝试获取复选框并点击
                checkbox = body.ele('@type:checkbox')
                checkbox.click()
                tab.wait(1)  # 点击后等待
            except Exception as e:
                # 如果复选框不存在，则记录信息并继续等待 cf_clearance
                print(f"第{attempt}次尝试：未找到复选框，继续等待 'cf_clearance'")

            # 等待 cf_clearance
            for wait_attempt in range(1, 11):
                cookies = tab.cookies().as_dict()
                if 'cf_clearance' in cookies:
                    print(f"成功获取 'cf_clearance'：{cookies['cf_clearance']}")
                    return cookies['cf_clearance']
                time.sleep(1)  # 等待1秒后重试

            # 如果等待后仍未找到 cf_clearance
            print(f"第{attempt}次尝试：未找到 'cf_clearance'。")

        except Exception as e:
            print(f"第{attempt}次尝试：发生异常 - {e}")

        # 刷新并重试
        tab.get(url)

    # 达到最大重试次数后仍未成功
    return None

@app.route('/get_cf_clearance', methods=['POST'])
def fetch_cf_clearance():
    data = request.get_json()

    if not data:
        return jsonify({"error": "未提供JSON负载。"}), 400

    proxy = data.get('proxy')
    user_agent = data.get('user_agent')
    url = data.get('url')

    if not proxy:
        return jsonify({"error": "缺少 'proxy' 参数。"}), 400

    if not url:
        return jsonify({"error": "缺少 'url' 参数。"}), 400
    browser = None
    try:
        browser, tab = initialize_browser(proxy=proxy, user_agent=user_agent)
        cf_clearance = get_cf_clearance(tab, url)

        if cf_clearance:
            response = {
                "proxy": proxy,
                "user_agent": user_agent,
                "cf_clearance": cf_clearance
            }
            return jsonify(response), 200
        else:
            return jsonify({"error": "未能获取到 'cf_clearance'。"}), 500

    except ValueError as ve:
        return jsonify({"error": str(ve)}), 400

    except Exception as e:
        return jsonify({"error": f"发生未预期的错误: {e}"}), 500

    finally:
        if browser:
            browser.quit()


@app.route('/', methods=['GET'])
def test():
    response = {"message": "cfpass is running."}

    # 从环境变量中获取是否返回公共IP的配置
    show_ip = os.getenv('SHOW_IP', 'false').lower() == 'true'

    if show_ip:
        try:
            # 发送请求到 api.ipify.org 获取公共IP
            ip_response = requests.get('https://api.ipify.org?format=json', timeout=5)
            if ip_response.status_code == 200:
                public_ip = ip_response.json().get('ip')
                response["public_ip"] = public_ip
            else:
                response["public_ip"] = f"无法获取IP，状态码: {ip_response.status_code}"
        except Exception as e:
            response["public_ip"] = f"无法获取IP: {e}"

    return jsonify(response), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
