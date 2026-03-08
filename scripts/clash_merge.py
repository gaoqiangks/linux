#!/usr/bin/env python3
import requests
import yaml
import base64
import re
import argparse
import sys
import os
import platform
from datetime import datetime

# ===================== 系统标准日志目录 + 双输出日志配置 =====================
class LogColor:
    INFO = '\033[0;37m'    # 白色 - 普通信息
    SUCCESS = '\033[0;32m' # 绿色 - 成功
    WARNING = '\033[0;31m' # 红色 - 失败/警告
    FATAL = '\033[1;31m'   # 高亮红色 - 致命错误
    RESET = '\033[0m'      # 重置颜色

def get_system_standard_log_dir():
    if platform.system() == 'Linux':
        log_dir = os.path.expanduser("~/.local/share/logs")
    elif platform.system() == 'Darwin':  # MacOS
        log_dir = os.path.expanduser("~/Library/Logs")
    elif platform.system() == 'Windows': # Windows
        log_dir = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Logs')
    else:
        log_dir = os.path.expanduser("~")
    os.makedirs(log_dir, exist_ok=True)
    return log_dir

LOG_DIR = get_system_standard_log_dir()
LOG_FILE_NAME = f"clash_merge_{datetime.now().strftime('%Y-%m-%d')}.log"
LOG_FILE_PATH = os.path.join(LOG_DIR, LOG_FILE_NAME)

def write_log_to_file(log_level, msg):
    try:
        log_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        log_content = f"[{log_time}] [{log_level}] {msg}\n"
        with open(LOG_FILE_PATH, 'a+', encoding='utf-8') as f:
            f.write(log_content)
    except Exception as e:
        print(f"{LogColor.WARNING}[LOG ERROR] 日志文件写入失败: {str(e)}{LogColor.RESET}", file=sys.stderr)

def log_info(msg):
    terminal_msg = f"{LogColor.INFO}[INFO] {msg}{LogColor.RESET}"
    print(terminal_msg, file=sys.stderr)
    write_log_to_file("INFO", msg)

def log_success(msg):
    terminal_msg = f"{LogColor.SUCCESS}[SUCCESS] {msg}{LogColor.RESET}"
    print(terminal_msg, file=sys.stderr)
    write_log_to_file("SUCCESS", msg)

def log_warning(msg):
    terminal_msg = f"{LogColor.WARNING}[WARNING] {msg}{LogColor.RESET}"
    print(terminal_msg, file=sys.stderr)
    write_log_to_file("WARNING", msg)

def log_fatal(msg):
    terminal_msg = f"{LogColor.FATAL}[FATAL ERROR] {msg}{LogColor.RESET}"
    print(terminal_msg, file=sys.stderr)
    write_log_to_file("FATAL ERROR", msg)

# ======================================================================================

# 固定默认路径配置
DEFAULT_BASE_DIR = r"C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件"
DEFAULT_SUBS_FILE = os.path.join(DEFAULT_BASE_DIR, "proxy.txt")
DEFAULT_RULES_FILE = os.path.join(DEFAULT_BASE_DIR, "rules.txt")
DEFAULT_YAML_FILE = os.path.join(DEFAULT_BASE_DIR, "clash_merge.yaml")
DEFAULT_GROUP_FILE = os.path.join(DEFAULT_BASE_DIR, "proxy_groups.yaml")
# 新增：-d模式下-p参数的默认属性文件路径
DEFAULT_PROPERTIES_FILE = os.path.join(DEFAULT_BASE_DIR, "group_properties.yaml")

# 确保默认目录存在
def ensure_default_dir():
    if not os.path.exists(DEFAULT_BASE_DIR):
        try:
            os.makedirs(DEFAULT_BASE_DIR, exist_ok=True)
            log_info(f"默认目录不存在，已自动创建: {DEFAULT_BASE_DIR}")
        except Exception as e:
            log_warning(f"创建默认目录失败: {str(e)}，将使用当前目录")

def decode_base64_content(content: str) -> str:
    """自动解码base64密文"""
    try:
        clean_content = content.strip()
        if not clean_content:
            return ""
        base64_pattern = re.compile(r'^[A-Za-z0-9+/]+={0,2}$')
        if not base64_pattern.match(clean_content):
            return clean_content
        missing_padding = len(clean_content) % 4
        if missing_padding:
            clean_content += '=' * (4 - missing_padding)
        decoded_bytes = base64.b64decode(clean_content)
        return decoded_bytes.decode('utf-8', errors='ignore')
    except Exception:
        return content

def extract_all_proxies_from_groups(proxy_groups: list, all_extracted: list, processed: set):
    """递归提取所有分组内嵌套的节点名称"""
    for group in proxy_groups:
        if isinstance(group, dict) and "name" in group and group["name"] not in processed:
            processed.add(group["name"])
            if "proxies" in group and isinstance(group["proxies"], list):
                for proxy_name in group["proxies"]:
                    if proxy_name not in ["DIRECT", "REJECT", "REJECT-DROP", "GLOBAL"] and proxy_name not in all_extracted:
                        all_extracted.append(proxy_name)
    return all_extracted

def process_single_subscribe(url: str, name_prefix: str = "") -> dict | None:
    """处理单个订阅：拉取全量节点+加前缀"""
    try:
        final_prefix = f"[{name_prefix}]" if name_prefix else ""
        headers = {
            "User-Agent": "clash-verge/v.2.4.4",
            "Accept": "*/*"
        }
        response = requests.get(url=url, headers=headers, allow_redirects=True, timeout=10)
        response.raise_for_status()
        
        raw_content = response.text
        decoded_content = decode_base64_content(raw_content)
        python_obj = yaml.safe_load(decoded_content)

        if not isinstance(python_obj, dict):
            log_warning(f"[{name_prefix}] 订阅内容解析失败: 非标准Clash配置格式")
            return None

        all_proxy_names_raw = []
        if "proxies" in python_obj and isinstance(python_obj["proxies"], list):
            for proxy in python_obj["proxies"]:
                if isinstance(proxy, dict) and "name" in proxy:
                    all_proxy_names_raw.append(proxy["name"])

        processed_groups = set()
        if "proxy-groups" in python_obj and isinstance(python_obj["proxy-groups"], list):
            all_proxy_names_raw = extract_all_proxies_from_groups(python_obj["proxy-groups"], all_proxy_names_raw, processed_groups)

        proxy_map = {}
        if "proxies" in python_obj:
            for proxy in python_obj["proxies"]:
                if isinstance(proxy, dict) and "name" in proxy:
                    proxy_map[proxy["name"]] = proxy
        
        final_proxies_list = []
        seen_names = set()
        for name in all_proxy_names_raw:
            if name in proxy_map and name not in seen_names:
                p = proxy_map[name].copy()
                p["name"] = f"{final_prefix}{p['name']}"
                final_proxies_list.append(p)
                seen_names.add(name)
        
        if len(final_proxies_list) > 0:
            log_success(f"[{name_prefix}] 处理成功，提取到 {len(final_proxies_list)} 个有效节点")
            return {"proxies": final_proxies_list}
        else:
            log_warning(f"[{name_prefix}] 处理完成，但未提取到任何有效节点")
            return None
    except requests.exceptions.RequestException as e:
        log_warning(f"[{name_prefix}] 订阅请求失败: {str(e)}")
        return None
    except Exception as e:
        log_warning(f"[{name_prefix}] 处理异常: {str(e)}")
        return None

def get_global_config():
    """返回全局配置（不含 rule-providers、proxy-groups 和 rules，后续单独拼接）"""
    return {
        "external-controller": "127.0.0.1:9090",
        "secret": "",
        "mixed-port": 7897,
        "allow-lan": False,
        "mode": "rule",
        "log-level": "info",
        "global-client-fingerprint": "firefox",
        "unified-delay": True,
        "ipv6": True,
        "profile": {"store-selected": True},
        "tun": {"mtu": 1500},
        "dns": {
            "enable": True,
            "ipv6": True,
            "use-system-hosts": False,
            "listen": "127.0.0.1:5335",
            "enhanced-mode": "fake-ip",
            "fake-ip-range": "198.18.0.1/16",
            "fake-ip-filter": [
                '*.lan', 'stun.*.*.*', 'stun.*.*', 'time.windows.com', 'time.nist.gov', 'time.apple.com', 'time.asia.apple.com',
                '*.ntp.org.cn', '*.openwrt.pool.ntp.org', 'time1.cloud.tencent.com', 'time.ustc.edu.cn', 'pool.ntp.org', 'ntp.ubuntu.com',
                'ntp.aliyun.com', 'ntp1.aliyun.com', 'ntp2.aliyun.com', 'ntp3.aliyun.com', 'ntp4.aliyun.com', 'ntp5.aliyun.com',
                'ntp6.aliyun.com', 'ntp7.aliyun.com', 'time1.aliyun.com', 'time2.aliyun.com', 'time3.aliyun.com', 'time4.aliyun.com',
                'time5.aliyun.com', 'time6.aliyun.com', 'time7.aliyun.com', '*.time.edu.cn', 'time1.apple.com', 'time2.apple.com',
                'time3.apple.com', 'time4.apple.com', 'time5.apple.com', 'time6.apple.com', 'time7.apple.com', 'time1.google.com',
                'time2.google.com', 'time3.google.com', 'time4.google.com', 'music.163.com', '*.music.163.com', '*.126.net',
                'musicapi.taihe.com', 'music.taihe.com', 'songsearch.kugou.com', 'trackercdn.kugou.com', '*.kuwo.cn',
                'api-jooxtt.sanook.com', 'api.joox.com', 'joox.com', 'y.qq.com', '*.y.qq.com', 'streamoc.music.tc.qq.com',
                'mobileoc.music.tc.qq.com', 'isure.stream.qqmusic.qq.com', 'dl.stream.qqmusic.qq.com', 'aqqmusic.tc.qq.com',
                'amobile.music.tc.qq.com', '*.xiami.com', '*.music.migu.cn', 'music.migu.cn', '*.msftconnecttest.com',
                '*.msftncsi.com', 'localhost.ptlogin2.qq.com', '*.*.*.srv.nintendo.net', '*.*.stun.playstation.net',
                'xbox.*.*.microsoft.com', '*.ipv6.microsoft.com', '*.*.xboxlive.com', 'speedtest.cros.wr.pvp.net'
            ],
            "default-nameserver": ["system", "180.76.76.76", "182.254.118.118", "8.8.8.8", "180.184.2.2", "2400:3200::1"],
            "nameserver": [
                'https://223.5.5.5/dns-query#skip-cert-verify=true',
                'https://doh.pub/dns-query#skip-cert-verify=true',
                'https://dns.alidns.com/dns-query#skip-cert-verify=true',
                'tls://223.5.5.5#skip-cert-verify=true',
                'tls://dot.pub#skip-cert-verify=true',
                'tls://dns.alidns.com#skip-cert-verify=true',
                'https://223.6.6.6/dns-query#skip-cert-verify=true&h3=true',
                'https://cloudflare-dns.com/dns-query#skip-cert-verify=true'
            ],
            "proxy-server-nameserver": [
                'https://223.5.5.5/dns-query#skip-cert-verify=true',
                'https://doh.pub/dns-query#skip-cert-verify=true',
                'https://dns.alidns.com/dns-query#skip-cert-verify=true',
                'tls://223.5.5.5#skip-cert-verify=true',
                'tls://dot.pub#skip-cert-verify=true',
                'tls://dns.alidns.com#skip-cert-verify=true',
                'https://223.6.6.6/dns-query#skip-cert-verify=true',
                'https://cloudflare-dns.com/dns-query#skip-cert-verify=true'
            ],
            "fallback-filter": {
                "geoip": True,
                "ipcidr": ["240.0.0.0/4", "0.0.0.0/3", "127.0.0.1/3"],
                "domain": [
                    "+.google.com", "+.facebook.com", "+.twitter.com", "+.youtube.com", "+.xn--ngstr-lra8j.com",
                    "+.google.cn", "+.googleapis.cn", "+.googleapis.com", "+.gvt1.com"
                ]
            }
        }
    }

def get_rule_providers():
    """返回14个规则集配置（rule-providers 内容）"""
    return {
        "reject": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt","path": "./ruleset/reject.yaml","interval": 86400},
        "icloud": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt","path": "./ruleset/icloud.yaml","interval": 86400},
        "apple": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt","path": "./ruleset/apple.yaml","interval": 86400},
        "google": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/google.txt","path": "./ruleset/google.yaml","interval": 86400},
        "proxy": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt","path": "./ruleset/proxy.yaml","interval": 86400},
        "direct": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt","path": "./ruleset/direct.yaml","interval": 86400},
        "private": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt","path": "./ruleset/private.yaml","interval": 86400},
        "gfw": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt","path": "./ruleset/gfw.yaml","interval": 86400},
        "tld-not-cn": {"type": "http","behavior": "domain","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt","path": "./ruleset/tld-not-cn.yaml","interval": 86400},
        "telegramcidr": {"type": "http","behavior": "ipcidr","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt","path": "./ruleset/telegramcidr.yaml","interval": 86400},
        "cncidr": {"type": "http","behavior": "ipcidr","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt","path": "./ruleset/cncidr.yaml","interval": 86400},
        "lancidr": {"type": "http","behavior": "ipcidr","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt","path": "./ruleset/lancidr.yaml","interval": 86400},
        "applications": {"type": "http","behavior": "classical","url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt","path": "./ruleset/applications.yaml","interval": 86400}
    }

def get_top_rules(main_group_name):
    """内置顶部规则（优先级低于自定义规则，全部指向PROXY）"""
    return [
        f"DOMAIN-SUFFIX,chat.openai.com,{main_group_name}",
        f"DOMAIN-SUFFIX,openai.com,{main_group_name}",
        f"DOMAIN-KEYWORD,chatgpt,{main_group_name}",
        f"DOMAIN-KEYWORD,openai,{main_group_name}",
        f"DOMAIN-SUFFIX,gemini.google.com,{main_group_name}",
        f"DOMAIN-KEYWORD,gemini,{main_group_name}",
        "DOMAIN-SUFFIX,1drv.com,DIRECT",
        "DOMAIN-SUFFIX,onedrive.com,DIRECT",
        "DOMAIN-SUFFIX,sharepoint.com,DIRECT",
        "DOMAIN-SUFFIX,officeapps.live.com,DIRECT",
        "DOMAIN-SUFFIX,skydrive.live.com,DIRECT",
        f"RULE-SET,google,{main_group_name}"
    ]

def get_bottom_rules():
    """内置底部规则（优先级最低）"""
    return [
        "RULE-SET,applications,DIRECT",
        "DOMAIN,clash.razord.top,DIRECT",
        "DOMAIN,yacd.haishan.me,DIRECT",
        "RULE-SET,private,DIRECT",
        "RULE-SET,reject,REJECT",
        "RULE-SET,icloud,DIRECT",
        "RULE-SET,apple,DIRECT",
        "RULE-SET,google,PROXY",
        "RULE-SET,proxy,PROXY",
        "RULE-SET,direct,DIRECT",
        "RULE-SET,lancidr,DIRECT",
        "RULE-SET,cncidr,DIRECT",
        "RULE-SET,telegramcidr,PROXY",
        "GEOIP,LAN,DIRECT",
        "GEOIP,CN,DIRECT",
        "MATCH,PROXY"
    ]

def read_custom_rules(rule_file_path):
    """读取自定义规则文件，返回规则列表"""
    custom_rules = []
    if not rule_file_path or not os.path.exists(rule_file_path):
        return custom_rules
    try:
        with open(rule_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            for line_num, line in enumerate(lines, 1):
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                custom_rules.append(line)
        if len(custom_rules) > 0:
            log_success(f"读取自定义规则文件成功，共加载 {len(custom_rules)} 条最高优先级规则")
        else:
            log_info(f"自定义规则文件存在，但未检测到有效规则")
    except Exception as e:
        log_warning(f"读取自定义规则文件异常: {str(e)}，将跳过自定义规则")
    return custom_rules

def read_subscribe_file(file_path):
    """读取订阅文件，解析为 机场名:订阅url 的字典"""
    subscribe_dict = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            log_info(f"开始解析订阅文件: {file_path}，共读取到 {len(lines)} 行内容")
            for line_num, line in enumerate(lines, 1):
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(maxsplit=1)
                if len(parts) == 2:
                    name, url = parts
                    name = name.strip()
                    url = url.strip()
                    subscribe_dict[name] = url
                else:
                    log_info(f"第 {line_num} 行: 格式不合法，自动忽略 -> {line}")
        log_success(f"订阅文件解析完成，共获取到 {len(subscribe_dict)} 个有效机场订阅")
        return subscribe_dict
    except FileNotFoundError:
        log_fatal(f"订阅文件不存在: {file_path}")
        sys.exit(1)
    except Exception as e:
        log_fatal(f"读取订阅文件失败: {str(e)}")
        sys.exit(1)

# ===================== 读取proxy-groups属性文件 =====================
def read_proxy_group_properties(properties_file):
    """
    读取proxy-groups属性文件，返回 {组名: 完整属性字典} 的映射
    :param properties_file: 属性文件路径
    :return: dict {group_name: group_dict}
    """
    if not properties_file or not os.path.exists(properties_file):
        log_info(f"指定的proxy-groups属性文件不存在: {properties_file}，跳过属性合并")
        return {}
    
    try:
        with open(properties_file, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            if not content:
                log_info(f"proxy-groups属性文件为空: {properties_file}，跳过属性合并")
                return {}
        
        # 解析属性文件（支持顶层是proxy-groups: [...] 或直接是列表）
        properties_data = yaml.safe_load(content)
        groups_dict = {}
        
        if isinstance(properties_data, dict) and "proxy-groups" in properties_data:
            # 顶层是proxy-groups的情况
            proxy_groups = properties_data["proxy-groups"]
        elif isinstance(properties_data, list):
            # 直接是列表的情况
            proxy_groups = properties_data
        else:
            log_warning(f"proxy-groups属性文件格式错误: {properties_file}，必须是proxy-groups字典或直接是列表")
            return {}
        
        # 生成组名到属性的映射
        for group in proxy_groups:
            if isinstance(group, dict) and "name" in group:
                group_name = group["name"].strip()
                groups_dict[group_name] = group.copy()
            else:
                log_warning(f"跳过属性文件中的无效代理组配置: {group}")
        
        log_success(f"读取proxy-groups属性文件成功: {properties_file}，共解析到 {len(groups_dict)} 个代理组属性")
        return groups_dict
    
    except yaml.YAMLError as e:
        log_warning(f"解析proxy-groups属性文件YAML失败: {properties_file} - {str(e)}，跳过属性合并")
        return {}
    except Exception as e:
        log_warning(f"读取proxy-groups属性文件异常: {properties_file} - {str(e)}，跳过属性合并")
        return {}

# ===================== 合并proxy-groups属性 =====================
def merge_proxy_group_properties(existing_groups_yaml, properties_dict):
    """
    将现有proxy-groups（YAML字符串）与属性字典合并，同名属性以properties为准
    :param existing_groups_yaml: 现有proxy-groups的YAML字符串
    :param properties_dict: {组名: 属性字典} 的映射
    :return: 合并后的proxy-groups YAML字符串
    """
    if not existing_groups_yaml or not properties_dict:
        return existing_groups_yaml
    
    try:
        # 解析现有proxy-groups为Python对象
        existing_groups = yaml.safe_load(existing_groups_yaml)
        if not isinstance(existing_groups, list):
            return existing_groups_yaml
        
        merged_groups = []
        merged_count = 0
        
        for existing_group in existing_groups:
            if not isinstance(existing_group, dict) or "name" not in existing_group:
                merged_groups.append(existing_group)
                continue
            
            group_name = existing_group["name"].strip()
            # 如果属性字典中有该组，进行属性合并
            if group_name in properties_dict:
                # 合并：现有属性 + 属性文件属性（后者覆盖前者）
                merged_group = existing_group.copy()
                merged_group.update(properties_dict[group_name])
                merged_groups.append(merged_group)
                merged_count += 1
                log_info(f"合并代理组[{group_name}]属性：属性文件中的配置覆盖同名属性")
            else:
                # 无匹配属性，保留原有配置
                merged_groups.append(existing_group)
        
        # 将合并后的组转回YAML字符串
        merged_yaml = yaml.dump(
            merged_groups,
            default_flow_style=False,
            sort_keys=False,
            indent=2,
            allow_unicode=True,
            encoding=None
        ).strip()
        
        log_success(f"proxy-groups属性合并完成：共合并 {merged_count} 个代理组的属性")
        return merged_yaml
    
    except yaml.YAMLError as e:
        log_warning(f"合并proxy-groups属性时YAML解析失败: {str(e)}，使用原有配置")
        return existing_groups_yaml
    except Exception as e:
        log_warning(f"合并proxy-groups属性时异常: {str(e)}，使用原有配置")
        return existing_groups_yaml

# ===================== 校验并清理自定义代理组中的无效节点 =====================
def validate_and_clean_proxy_groups(raw_yaml_content, valid_proxy_names):
    """
    校验自定义代理组中的节点是否存在于PROXY分组中，清理无效节点
    :param raw_yaml_content: proxy_groups.yaml的原始文本内容
    :param valid_proxy_names: PROXY分组中的有效节点名称集合
    :return: 清理后的代理组YAML文本内容
    """
    if not raw_yaml_content:
        return ""
    
    try:
        # 解析自定义代理组为Python对象
        proxy_groups = yaml.safe_load(raw_yaml_content)
        if not isinstance(proxy_groups, list):
            log_warning("自定义代理组文件格式错误：必须是列表类型")
            return ""
        
        cleaned_groups = []
        total_invalid_nodes = 0
        
        for group in proxy_groups:
            if not isinstance(group, dict) or "name" not in group:
                log_warning(f"跳过无效的代理组配置: {group}")
                continue
            
            group_name = group["name"]
            cleaned_group = group.copy()
            
            # 新增：给每个代理组添加 tolerance: 100 字段（如果不存在则添加）
            cleaned_group["tolerance"] = 100
            
            # 仅校验 proxies 字段中的节点
            if "proxies" in cleaned_group and isinstance(cleaned_group["proxies"], list):
                original_proxies = cleaned_group["proxies"]
                cleaned_proxies = []
                
                for proxy in original_proxies:
                    # 保留系统内置节点（DIRECT/REJECT等），仅校验自定义节点
                    if proxy in ["DIRECT", "REJECT", "REJECT-DROP", "GLOBAL", "PROXY"]:
                        cleaned_proxies.append(proxy)
                    elif proxy in valid_proxy_names:
                        cleaned_proxies.append(proxy)
                    else:
                        total_invalid_nodes += 1
                        log_warning(f"代理组[{group_name}]中移除无效节点: {proxy}（该节点不存在于PROXY分组）")
                
                # 更新为清理后的节点列表
                cleaned_group["proxies"] = cleaned_proxies
                # 如果清理后proxies为空，跳过该分组
                if not cleaned_proxies:
                    log_warning(f"代理组[{group_name}]所有节点均无效，已跳过该分组")
                    continue
            
            cleaned_groups.append(cleaned_group)
        
        # 将清理后的代理组转回YAML文本
        if cleaned_groups:
            cleaned_yaml = yaml.dump(
                cleaned_groups,
                default_flow_style=False,
                sort_keys=False,
                indent=2,
                allow_unicode=True,
                encoding=None
            ).strip()
            log_success(f"自定义代理组校验完成：共移除 {total_invalid_nodes} 个无效节点，且已为所有组添加 tolerance: 100")
            return cleaned_yaml
        else:
            log_warning("自定义代理组所有内容均无效，已跳过")
            return ""
    
    except yaml.YAMLError as e:
        log_warning(f"解析自定义代理组YAML失败: {str(e)}")
        return ""
    except Exception as e:
        log_warning(f"清理自定义代理组节点时异常: {str(e)}")
        return ""

def read_and_validate_proxy_groups(file_path, valid_proxy_names):
    """
    读取并校验自定义代理组文件
    :param file_path: proxy_groups.yaml路径
    :param valid_proxy_names: PROXY分组中的有效节点名称集合
    :return: 清理后的代理组YAML文本
    """
    if not file_path or not os.path.exists(file_path):
        log_info("自定义代理组文件（proxy_groups.yaml）不存在，将只生成默认分组")
        return ""
    
    try:
        # 读取原始内容（去除注释和空行）
        raw_lines = []
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f.readlines():
                stripped_line = line.strip()
                if not stripped_line or stripped_line.startswith('#'):
                    continue
                raw_lines.append(line)
        
        raw_content = ''.join(raw_lines).strip()
        if not raw_content:
            log_info("自定义代理组文件（proxy_groups.yaml）无有效内容，将只生成默认分组")
            return ""
        
        # 校验并清理无效节点
        cleaned_content = validate_and_clean_proxy_groups(raw_content, valid_proxy_names)
        return cleaned_content
    
    except Exception as e:
        log_warning(f"读取/校验自定义代理组文件异常: {str(e)}，将只生成默认分组")
        return ""

# 仅生成默认 PROXY 全量节点分组
def generate_default_groups_yaml(all_proxy_names):
    """
    仅生成默认 PROXY 全量节点分组，已彻底移除英美印加相关逻辑
    新增：给默认PROXY分组添加 tolerance: 100 字段
    """
    default_groups = []
    main_group_name = "PROXY"
    
    # 只保留全量节点的PROXY分组，新增 tolerance: 100
    proxy_group = {
        "name": main_group_name, 
        "type": "url-test",
        "url": "http://www.gstatic.com/generate_204",
        "interval": 300,
        "tolerance": 100,  # 新增字段
        "proxies": all_proxy_names 
    }
    default_groups.append(proxy_group)
    
    # 转为标准YAML
    group_yaml = yaml.dump(
        default_groups,
        default_flow_style=False,
        sort_keys=False,
        indent=2,
        allow_unicode=True,
        encoding=None
    ).strip()
    
    log_info(f"生成默认分组完成: {main_group_name}(全量{len(all_proxy_names)}节点)，已添加 tolerance: 100")
    return group_yaml, main_group_name

# ===================== 核心修复：proxy-groups 缩进 =====================
def build_final_yaml(merged_config, rule_providers, default_groups_yaml, custom_group_cleaned, final_rules):
    """
    节点顺序（官方规范）：全局配置 → rule-providers → proxies → proxy-groups → rules
    规则顺序：自定义规则(最高) → 内置top规则 → 内置bottom规则
    """
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header_comment = f"# Clash配置文件 - 由订阅合并脚本自动生成 | 生成时间: {current_time}\n\n"
    
    # 全局配置
    main_yaml = yaml.dump(
        merged_config,
        default_flow_style=False,
        sort_keys=False,
        indent=2,
        allow_unicode=True,
        encoding=None
    ).strip()
    
    # rule-providers 保持原有正确缩进
    rule_providers_yaml = ""
    if rule_providers:
        rule_providers_content = yaml.dump(
            rule_providers,
            default_flow_style=False,
            sort_keys=False,
            indent=2,
            allow_unicode=True,
            encoding=None
        ).strip()
        rule_providers_yaml = f"\nrule-providers:\n  {rule_providers_content.replace('\n', '\n  ')}"
    
    # 拼接默认+自定义代理组
    pg_parts = []
    if default_groups_yaml:
        pg_parts.append(default_groups_yaml)
    if custom_group_cleaned:
        pg_parts.append(custom_group_cleaned)
    
    pg_combined = "\n\n".join(pg_parts) if pg_parts else ""
    proxy_groups_yaml = f"\n\nproxy-groups:\n{pg_combined}" if pg_combined else "\n\nproxy-groups:"
    
    # rules 保持原有正确缩进
    rules_yaml = ""
    if final_rules:
        rules_content = yaml.dump(
            final_rules,
            default_flow_style=False,
            sort_keys=False,
            indent=2,
            allow_unicode=True,
            encoding=None
        ).strip()
        rules_yaml = f"\n\nrules:\n  {rules_content.replace('\n', '\n  ')}"
    
    # 最终拼接
    final_yaml = header_comment + main_yaml + rule_providers_yaml + proxy_groups_yaml + rules_yaml + "\n"
    return final_yaml

def batch_process_and_merge(subscribe_dict: dict, custom_rule_path: str, custom_group_file=None, properties_file=None):
    """核心逻辑，新增自定义代理组节点校验 + 属性文件合并"""
    merged_config = get_global_config()
    merged_config["proxies"] = []
    rule_providers = get_rule_providers()
    final_rules = []
    all_proxy_names = []
    
    total_node_count = 0
    success_subscribe_count = 0
    total_subscribe_count = len(subscribe_dict)
    
    log_info(f"开始批量处理所有机场订阅 | 共 {total_subscribe_count} 个订阅源待处理...")
    
    for sub_name, sub_url in subscribe_dict.items():
        sub_config = process_single_subscribe(sub_url, sub_name)
        if sub_config and "proxies" in sub_config and len(sub_config["proxies"]) > 0:
            merged_config["proxies"].extend(sub_config["proxies"])
            node_count = len(sub_config["proxies"])
            total_node_count += node_count
            success_subscribe_count += 1
            for p in sub_config["proxies"]:
                if isinstance(p, dict) and "name" in p:
                    all_proxy_names.append(p["name"])

    failed_subscribe_count = total_subscribe_count - success_subscribe_count
    log_info(f"订阅处理统计: 成功 {success_subscribe_count} 个 / 失败 {failed_subscribe_count} 个 / 总计 {total_subscribe_count} 个")
    
    if failed_subscribe_count >= total_subscribe_count / 2:
        log_fatal(f"致命错误：超过一半的订阅源无有效节点，终止生成配置！")
        sys.exit(1)

    log_success(f"所有订阅处理完成，累计提取到 {total_node_count} 个有效节点 (已去重)")
    
    # 生成默认PROXY分组
    default_groups_yaml, main_group_name = generate_default_groups_yaml(all_proxy_names)
    
    # 校验自定义代理组中的节点有效性
    valid_proxy_set = set(all_proxy_names)
    custom_group_cleaned = read_and_validate_proxy_groups(custom_group_file, valid_proxy_set)
    
    # 读取属性文件并合并代理组属性
    properties_dict = read_proxy_group_properties(properties_file)
    if properties_dict:
        # 合并默认分组属性
        if default_groups_yaml:
            default_groups_yaml = merge_proxy_group_properties(default_groups_yaml, properties_dict)
        # 合并自定义分组属性
        if custom_group_cleaned:
            custom_group_cleaned = merge_proxy_group_properties(custom_group_cleaned, properties_dict)
    
    # 规则优先级：自定义 > 内置top > 内置bottom
    custom_rules = read_custom_rules(rule_file_path=custom_rule_path)
    top_rules = get_top_rules(main_group_name)
    bottom_rules = get_bottom_rules()
    final_rules = custom_rules + top_rules + bottom_rules
    
    return merged_config, rule_providers, default_groups_yaml, custom_group_cleaned, final_rules

# ------------------- 命令行入口：-d模式自动加载默认属性文件 -------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='🔥 Clash订阅合并+规则生成脚本（带自定义代理组节点校验 + 缩进修复 + tolerance + 属性合并）🔥',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        add_help=False,
        epilog=r"""
【核心参数说明】
  -d/--default    快速执行：使用脚本内置默认路径，一键生成配置
                  (默认属性文件: C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\group_properties.yaml)
  -s/--subscribe  自定义：指定机场订阅列表文件路径（每行 机场别名,订阅链接）
  -r/--rules      自定义：指定自定义规则文件路径（规则优先级最高，会覆盖内置同名规则）
  -g/--group      自定义：指定自定义代理组文件路径（固定为 proxy_groups.yaml）
  -y/--yaml       自定义：指定最终输出的Clash配置文件路径
  -p/--properties 自定义：指定proxy-groups属性文件路径（用于合并扩展属性，同名属性以该文件为准）
                  (-d模式下未指定时，自动使用默认路径)
  -h/--help       显示此详细帮助信息并退出

【当前版本完整特性】
  ✔ 彻底移除所有「英美印加节点」相关分组、筛选、规则代码，无残留
  ✔ 自定义代理组文件标准命名：proxy_groups.yaml，纯文本读取保留原始YAML格式
  ✔ 自动校验proxy_groups.yaml中所有节点：仅保留存在于PROXY分组的节点，无效节点自动删除
  ✔ 修复proxy-groups缩进问题：输出标准Clash格式，无多余嵌套缩进
  ✔ 为所有proxy-groups中的代理组自动添加 tolerance: 100 字段
  ✔ 新增-p/--properties：合并proxy-groups扩展属性，同名属性以指定文件为准
  ✔ -d模式下自动加载默认属性文件：group_properties.yaml
  ✔ rule-providers、rules 缩进完全符合Clash官方规范，可直接导入
  ✔ 自定义规则(rules.txt)优先级最高，可自由扩展/覆盖内置规则
  ✔ 节点命名自动添加机场前缀，避免不同机场同名节点冲突
  ✔ 自动过滤订阅内无效节点、过期提示文字节点
  ✔ 完整双路日志输出：控制台彩色日志 + 文件日志，方便排错
  ✔ 支持Base64编码订阅自动解码，兼容绝大多数Clash订阅格式
  ✔ 全局配置、DNS、规则集全部采用通用稳定配置，开箱可用

【默认文件路径（使用 -d 参数时自动加载）】
  订阅文件:      C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\proxy.txt
  自定义规则:    C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\rules.txt
  自定义代理组:  C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\proxy_groups.yaml
  默认属性文件:  C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\group_properties.yaml
  输出配置:      C:\Users\gaoqiang\OneDrive\WorkSpace\settings\clash配置文件\clash_merge.yaml

【属性文件格式说明（-p/--properties）】
  支持两种格式：
  1. 标准格式（推荐）：
     proxy-groups:
     - name: "proxy1"
       type: select
       proxies:
       - DIRECT
       - ss
       use:
       - provider1
       url: 'https://www.gstatic.com/generate_204'
       interval: 300
       lazy: true
       timeout: 5000
       max-failed-times: 5
       disable-udp: true
       interface-name: en0
       routing-mark: 11451
       include-all: false
  
  2. 简化格式（直接列表）：
     - name: "proxy1"
       type: select
       ...

【使用示例】
  1. 一键默认模式(自动加载默认属性文件):
     python clash_merge.py -d

  2. 默认模式+指定属性文件(覆盖默认路径):
     python clash_merge.py -d -p ./my_group_properties.yaml

  3. 完全自定义模式:
     python clash_merge.py -s ./my_subscribe.txt -r ./my_rules.txt -g ./proxy_groups.yaml -y ./final_config.yaml -p ./group_properties.yaml

【注意事项】
  1. 脚本会自动过滤不存在于默认PROXY分组的节点，防止Clash启动报错
  2. DIRECT/REJECT/PROXY等系统内置分组会被保留，不会被过滤
  3. 无proxy_groups.yaml时，仅输出默认PROXY分组，不影响使用
  4. 日志文件自动保存在系统日志目录，可用于排查节点丢失/格式错误问题
  5. 所有代理组都会自动添加 tolerance: 100 字段，无需手动编写
  6. 属性文件中存在但最终配置中没有的代理组，不会被添加到最终配置
  7. 属性文件中的属性会覆盖最终配置中的同名属性（如interval、timeout等）
  8. -d模式下若默认属性文件不存在，会自动跳过属性合并，不影响脚本运行
"""
    )
    
    parser.add_argument('-d', '--default', action='store_true', help='快速执行：使用默认路径一键生成配置（自动加载默认属性文件）')
    parser.add_argument('-s', '--subscribe', type=str, help='自定义：指定订阅文件路径')
    parser.add_argument('-r', '--rules', type=str, help='自定义：指定自定义规则文件路径')
    parser.add_argument('-g', '--group', type=str, help='自定义：指定自定义代理组文件路径(proxy_groups.yaml)')
    parser.add_argument('-y', '--yaml', type=str, help='自定义：指定最终输出配置文件路径')
    parser.add_argument('-p', '--properties', type=str, help='自定义：指定proxy-groups属性文件路径（-d模式默认使用group_properties.yaml）')
    parser.add_argument('-h', '--help', action='store_true', help='显示详细帮助信息')
    
    args = parser.parse_args()

    if len(sys.argv) == 1 or args.help:
        parser.print_help()
        sys.exit(0)
    
    if args.default:
        log_info("===== 触发默认路径模式 =====")
        ensure_default_dir()
        subs_file = DEFAULT_SUBS_FILE
        rules_file = DEFAULT_RULES_FILE
        group_file = DEFAULT_GROUP_FILE
        yaml_file = DEFAULT_YAML_FILE
        
        # 核心修改：-d模式下自动使用默认属性文件（未指定-p时）
        if args.properties:
            properties_file = args.properties
            log_info(f"指定proxy-groups属性文件: {properties_file}（覆盖默认路径）")
        else:
            properties_file = DEFAULT_PROPERTIES_FILE
            log_info(f"使用默认proxy-groups属性文件: {properties_file}")
        
        log_info(f"默认订阅文件: {subs_file}")
        log_info(f"默认自定义规则文件: {rules_file}（规则优先级最高）")
        log_info(f"默认自定义代理组文件: {group_file}")
        log_info(f"最终输出配置文件: {yaml_file}")
        
        MY_SUBSCRIBES = read_subscribe_file(subs_file)
        merged_cfg, rp, def_grp, custom_grp, final_r = batch_process_and_merge(
            MY_SUBSCRIBES, rules_file, group_file, properties_file
        )
        final_yaml_content = build_final_yaml(merged_cfg, rp, def_grp, custom_grp, final_r)
        
        with open(yaml_file, 'w', encoding='utf-8') as f:
            f.write(final_yaml_content)
        log_success(f"配置文件生成完成，已写入: {yaml_file}")
        log_info("可直接将该文件导入Clash、Clash Verge等客户端使用")
        sys.exit(0)
    
    if not args.subscribe:
        log_fatal("错误：非默认模式下必须指定 -s/--subscribe 订阅文件路径")
        print("\n使用帮助: python clash_merge.py -h")
        sys.exit(1)
    
    log_info("===== 自定义路径模式 =====")
    log_info(f"指定订阅文件: {args.subscribe}")
    if args.rules:
        log_info(f"指定自定义规则文件: {args.rules}")
    if args.group:
        log_info(f"指定自定义代理组文件: {args.group}")
    if args.properties:
        log_info(f"指定proxy-groups属性文件: {args.properties}")
    if args.yaml:
        log_info(f"指定输出配置文件: {args.yaml}")
    
    MY_SUBSCRIBES = read_subscribe_file(args.subscribe)
    merged_cfg, rp, def_grp, custom_grp, final_r = batch_process_and_merge(
        MY_SUBSCRIBES, args.rules, args.group, args.properties
    )
    final_yaml_content = build_final_yaml(merged_cfg, rp, def_grp, custom_grp, final_r)
    
    if args.yaml:
        with open(args.yaml, 'w', encoding='utf-8') as f:
            f.write(final_yaml_content)
        log_success(f"配置文件生成完成，已写入: {args.yaml}")
    else:
        log_info("未指定输出文件，将直接打印配置内容到控制台")
        print("\n" + final_yaml_content)
    
    log_info("脚本执行完毕")