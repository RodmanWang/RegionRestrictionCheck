#!/bin/bash
shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

while getopts ":I:M:E:X:P:F:S:" optname; do
    case "$optname" in
        "I")
            iface="$OPTARG"
            useNIC="--interface $iface"
        ;;
        "M")
            if [[ "$OPTARG" == "4" ]]; then
                NetworkType=4
                elif [[ "$OPTARG" == "6" ]]; then
                NetworkType=6
            fi
        ;;
        "E")
            language="e"
        ;;
        "X")
            XIP="$OPTARG"
            xForward="--header X-Forwarded-For:$XIP"
        ;;
        "P")
            proxy="$OPTARG"
            usePROXY="-x $proxy"
        ;;
        "F")
            func="$OPTARG"
        ;;
        "S")
            Stype="$OPTARG"
        ;;
        ":")
            echo "Unknown error while processing options"
            exit 1
        ;;
    esac
    
done

if [ -z "$iface" ]; then
    useNIC=""
fi

if [ -z "$XIP" ]; then
    xForward=""
fi

if [ -z "$proxy" ]; then
    usePROXY=""
fi

if ! mktemp -u --suffix=RRC &>/dev/null; then
    is_busybox=1
fi
curlArgs="$useNIC $usePROXY $xForward"
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"
Media_Cookie=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/cookies")
IATACode=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/reference/IATACode.txt")

countRunTimes() {
    if [ "$is_busybox" == 1 ]; then
        count_file=$(mktemp)
    else
        count_file=$(mktemp --suffix=RRC)
    fi
    RunTimes=$(curl -s --max-time 10 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F1-stream%2FRegionRestrictionCheck&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false" >"${count_file}")
    TodayRunTimes=$(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $5}')
    TotalRunTimes=$(($(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $7}') + 0))
}
countRunTimes

checkOS() {
    ifTermux=$(echo $PWD | grep termux)
    ifMacOS=$(uname -a | grep Darwin)
    if [ -n "$ifTermux" ]; then
        os_version=Termux
        is_termux=1
        elif [ -n "$ifMacOS" ]; then
        os_version=MacOS
        is_macos=1
    else
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    fi
    
    if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]]; then
        is_windows=1
        ssll="-k --ciphers DEFAULT@SECLEVEL=1"
    fi
    
    if [ "$(which apt 2>/dev/null)" ]; then
        InstallMethod="apt"
        is_debian=1
        elif [ "$(which dnf 2>/dev/null)" ] || [ "$(which yum 2>/dev/null)" ]; then
        InstallMethod="yum"
        is_redhat=1
        elif [[ "$os_version" == "Termux" ]]; then
        InstallMethod="pkg"
        elif [[ "$os_version" == "MacOS" ]]; then
        InstallMethod="brew"
    fi
}
checkOS

checkCPU() {
    CPUArch=$(uname -m)
    if [[ "$CPUArch" == "aarch64" ]]; then
        arch=_arm64
        elif [[ "$CPUArch" == "i686" ]]; then
        arch=_i686
        elif [[ "$CPUArch" == "arm" ]]; then
        arch=_arm
        elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ]; then
        arch=_darwin
    fi
}
checkCPU

checkDependencies() {
    
    # os_detail=$(cat /etc/os-release 2> /dev/null)
    
    if ! command -v python &>/dev/null; then
        if command -v python3 &>/dev/null; then
            alias python="python3"
        else
            if [ "$is_debian" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                elif [ "$is_redhat" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                if [[ "$os_version" -gt 7 ]]; then
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                    alias python="python3"
                else
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                fi
                
                elif [ "$is_termux" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update -y >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                
                elif [ "$is_macos" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod install python3
                alias python="python3"
            fi
        fi
    fi
    
    if ! command -v dig &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing bind-utils${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install bind-utils -y >/dev/null 2>&1
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing bind${Font_Suffix}"
            $InstallMethod install bind
        fi
    fi
    
    if ! command -v jq &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod install jq
        fi
    fi
    
    if [ "$is_macos" == 1 ]; then
        if ! command -v md5sum &>/dev/null; then
            echo -e "${Font_Green}Installing md5sha1sum${Font_Suffix}"
            $InstallMethod install md5sha1sum
        fi
    fi
    
}
checkDependencies

local_ipv4=$(curl $curlArgs -4 -s --max-time 10 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}')
local_ipv4_asterisk=$(awk -F"." '{print $1"."$2".*.*"}' <<<"${local_ipv4}")
local_ipv6=$(curl $curlArgs -6 -s --max-time 20 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}')
local_ipv6_asterisk=$(awk -F":" '{print $1":"$2":"$3":*:*"}' <<<"${local_ipv6}")
local_isp4=$(curl $curlArgs -s -4 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/" | jq '.organization' | tr -d '"' &)
local_isp6=$(curl $curlArgs -s -6 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/" | jq '.organization' | tr -d '"' &)

ShowRegion() {
    echo -e "${Font_Yellow} ---${1}---${Font_Suffix}"
}

function detect_isp() {
    local lan_ip=$(echo "$1" | grep -Eo "^(10\.[0-9]{1,3}\.[0-9]{1,3}\.((0\/([89]|1[0-9]|2[0-9]|3[012]))|([0-9]{1,3})))|(172\.(1[6789]|2\[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)$")
    if [ -n "$lan_ip" ]; then
        echo "LAN"
        return
    else
        local res=$(curl $curlArgs --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$1" | jq ".isp" | tr -d '"' )
        echo "$res"
        return
    fi
}

function GameTest_Steam() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://store.steampowered.com/app/761830" 2>&1 | grep priceCurrency | cut -d '"' -f4)

    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam Currency:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    else
        echo -n -e "\r Steam Currency:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HBONow() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 --write-out "%{url_effective}\n" --output /dev/null "https://play.hbonow.com/" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        if [ "${result}" = "https://play.hbonow.com" ] || [ "${result}" = "https://play.hbonow.com/" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "http://hbogeo.cust.footprint.net/hbonow/geo.html" ] || [ "${result}" = "http://geocust.hbonow.com/hbonow/geo.html" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        fi
    else
        echo -e "\r HBO Now:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BahamutAnime() {
    local tmpdeviceid=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" --max-time 10 -fsSL "https://ani.gamer.com.tw/ajax/getdeviceid.php" --cookie-jar bahamut_cookie.txt 2>&1)
    if [[ "$tmpdeviceid" == "curl"* ]]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local tempdeviceid=$(echo $tmpdeviceid | python -m json.tool 2>/dev/null | grep 'deviceid' | awk '{print $2}' | tr -d '"' )
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" --max-time 10 -fsSL "https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=14667&device=${tempdeviceid}" -b bahamut_cookie.txt 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    rm bahamut_cookie.txt
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'animeSn')
    if [ -n "$result" ]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BilibiliHKMCTW() {
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        local result="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
        if [ "${result}" = "0" ]; then
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "-10403" ]; then
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

# 流媒体解锁测试-哔哩哔哩台湾限定
function MediaUnlockTest_BilibiliTW() {
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi" 2>&1)
    if [[ "$result" != "curl"* ]]; then
        local result="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
        if [ "${result}" = "0" ]; then
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        elif [ "${result}" = "-10403" ]; then
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
}

# 流媒体解锁测试-Abema.TV
#
function MediaUnlockTest_AbemaTV_IPTest() {
    local tempresult=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --max-time 10 "https://api.abema.io/v1/ip/check?device=android" 2>&1)
    if [[ "$tempresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tempresult" == "curl"* ]]; then
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(echo "$tempresult" | python -m json.tool 2>/dev/null | grep isoCountryCode | awk '{print $2}' | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [[ "$result" == "JP" ]]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        else
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Yellow}Oversea Only (Region: ${result})${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_PCRJP() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api-priconne-redive.cygames.jp/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_UMAJP() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api-umamusume.cygames.jp/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Pretty Derby Japan:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_WFJP() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.worldflipper.jp/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r World Flipper Japan:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r World Flipper Japan:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r World Flipper Japan:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r World Flipper Japan:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Kancolle() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "http://203.104.209.7/kcscontents/news/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Kancolle Japan:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_BBCiPLAYER() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --max-time 10 "https://open.live.bbc.co.uk/mediaselector/6/select/version/2.0/mediaset/pc/vpid/bbc_one_london/format/json/jsfunc/JS_callbacks0" 2>&1)
    if [ "${tmpresult}" = "000" ]; then
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    if [ -n "$tmpresult" ]; then
        result=$(echo $tmpresult | grep 'geolocation')
        if [ -n "$result" ]; then
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        else
            echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        fi
    else
        echo -n -e "\r BBC iPLAYER:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Netflix() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81280792" 2>&1)
    local result2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/70143836" 2>&1)
    local region=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fs --max-time 10 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/title/80018499" 2>&1 | cut -d '/' -f4 | cut -d '-' -f1 | tr [:lower:] [:upper:])
    if [[ ! -n "$region" ]]; then
        region="US"
	fi
    if [[ "$result1" == "404" ]] && [[ "$result2" == "404" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Originals Only (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result1" == "403" ]] && [[ "$result2" == "403" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result1" == "200" ]] || [[ "$result2" == "200" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_DisneyPlus() {
    local PreAssertion=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1)
    if [[ "$PreAssertion" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$PreAssertion" == "curl"* ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local assertion=$(echo $PreAssertion | python -m json.tool 2>/dev/null | grep assertion | cut -f4 -d'"')
    local PreDisneyCookie=$(echo "$Media_Cookie" | sed -n '1p')
    local disneycookie=$(echo $PreDisneyCookie | sed "s/DISNEYASSERTION/${assertion}/g")
    local TokenContent=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycookie" 2>&1)
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(echo "$Media_Cookie" | sed -n '8p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local disneycontent=$(echo $fakecontent | sed "s/ILOVEDISNEY/${refreshToken}/g")
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$disneycontent" 2>&1)
    local previewcheck=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.disneyplus.com" | grep preview)
    local isUnabailable=$(echo $previewcheck | grep 'unavailable')
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "JP" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: JP)${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "false" ]] && [ -z "$isUnabailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Yellow}Available For [Disney+ $region] Soon${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Disney+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Dazn() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -X POST -H "Content-Type: application/json" -d '{"LandingPageKey":"generic","Languages":"zh-CN,zh,en","Platform":"web","PlatformAttributes":{},"Manufacturer":"","PromoCode":"","Version":"2"}' "https://startup.core.indazn.com/misl/v5/Startup" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    isAllowed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'isAllowed' | awk '{print $2}' | cut -f1 -d',')
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"GeolocatedCountry":' | awk '{print $2}' | cut -f2 -d'"')

    if [[ "$isAllowed" == "true" ]]; then
        local CountryCode=$(echo $result | tr [:lower:] [:upper:])
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Green}Yes (Region: ${CountryCode})${Font_Suffix}\n"
        return
    elif [[ "$isAllowed" == "false" ]]; then
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Dazn:\t\t\t\t\t${Font_Red}Unsupport${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_HuluJP() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://id.hulu.jp" 2>&1 | grep 'restrict')

    if [ -n "$result" ]; then
        echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Hulu Japan:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_MyTVSuper() {
    local result=$(curl $curlArgs -s -${1} --max-time 10 "https://www.mytvsuper.com/api/auth/getSession/self/" 2>&1 | python -m json.tool 2>/dev/null | grep 'region' | awk '{print $2}' | tr -d ",")

    if [[ "$result" == "1" ]]; then
        echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MyTVSuper:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_NowE() {

    local result=$(curl $curlArgs -${1} -s --max-time 10 -X POST -H "Content-Type: application/json" -d '{"contentId":"202105121370235","contentType":"Vod","pin":"","deviceId":"W-60b8d30a-9294-d251-617b-6oagagn3","deviceType":"WEB"}' "https://webtvapi.nowe.com/16/1/getVodURL" | python -m json.tool 2>/dev/null | grep 'responseCode' | awk '{print $2}' | cut -f2 -d'"' 2>&1)

    if [[ "$result" == "SUCCESS" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "PRODUCT_INFORMATION_INCOMPLETE" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "GEO_CHECK_FAIL" ]]; then
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Now E:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ViuTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 -X POST -H "Content-Type: application/json" -d '{"callerReferenceNo":"20210726112323","contentId":"099","contentType":"Channel","channelno":"099","mode":"prod","deviceId":"29b3cb117a635d5b56","deviceType":"ANDROID_WEB"}' "https://api.viu.now.com/p8/3/getLiveURL" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'responseCode' | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "SUCCESS" ]]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "GEO_CHECK_FAIL" ]]; then
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Viu.TV:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_unext() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://cc.unext.jp/" -X POST -d '{"operationName":"cosmo_getPlaylistUrl","variables":{"code":"ED00467205","playMode":"caption","bitrateLow":192,"bitrateHigh":null,"validationOnly":false},"query":"query cosmo_getPlaylistUrl($code: String, $playMode: String, $bitrateLow: Int, $bitrateHigh: Int, $validationOnly: Boolean) {\n  webfront_playlistUrl(\n    code: $code\n    playMode: $playMode\n    bitrateLow: $bitrateLow\n    bitrateHigh: $bitrateHigh\n    validationOnly: $validationOnly\n  ) {\n    subTitle\n    playToken\n    playTokenHash\n    beaconSpan\n    result {\n      errorCode\n      errorMessage\n      __typename\n    }\n    resultStatus\n    licenseExpireDate\n    urlInfo {\n      code\n      startPoint\n      resumePoint\n      endPoint\n      endrollStartPosition\n      holderId\n      saleTypeCode\n      sceneSearchList {\n        IMS_AD1\n        IMS_L\n        IMS_M\n        IMS_S\n        __typename\n      }\n      movieProfile {\n        cdnId\n        type\n        playlistUrl\n        movieAudioList {\n          audioType\n          __typename\n        }\n        licenseUrlList {\n          type\n          licenseUrl\n          __typename\n        }\n        __typename\n      }\n      umcContentId\n      movieSecurityLevelCode\n      captionFlg\n      dubFlg\n      commodityCode\n      movieAudioList {\n        audioType\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n"}' -H "Content-Type: application/json" )
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'resultStatus' | awk '{print $2}' | cut -d ',' -f1 2>&1)
    if [ -n "$result" ]; then
        if [[ "$result" == "475" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        elif [[ "$result" == "200" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        elif [[ "$result" == "467" ]]; then
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r U-NEXT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Paravi() {
    local tmpresult=$(curl $curlArgs -${1} -Ss --max-time 10 -H "Content-Type: application/json" -d '{"meta_id":17414,"vuid":"3b64a775a4e38d90cc43ea4c7214702b","device_code":1,"app_id":1}' "https://api.paravi.jp/api/v1/playback/auth" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep type | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "Forbidden" ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "Unauthorized" ]]; then
        echo -n -e "\r Paravi:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_wowow() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -s --max-time 10 "https://mapi.wowow.co.jp/api/v1/playback/auth" -X POST -d '{"meta_id":81174}' -H "Content-Type: application/json" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | jq '.error.code')
    if [[ "$checkfailed" == "2055" ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "2041" ]] || [[ "$checkfailed" == "2003" ]]; then
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r WOWOW:\t\t\t\t\t${Font_Red}Unknown (Code: $checkfailed)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_TVer() {
    local BCpktmp=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 "https://players.brightcove.net/4394098882001/L3xqlxT7zF_default/index.min.js"  2>&1)
    if [[ "$BCpktmp" == "curl"* ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local BCpk=$(echo $BCpktmp |grep -Eo 'BCpk(.|)*"}},{name:"dock",autoInit:false}')
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 -H "Accept: application/json;pk=${BCpk:0:-32}" "https://edge.api.brightcove.com/playback/v1/accounts/4394098882001/videos/ref%3A83b847b3-f6a6-4b3a-b69c-f27b1e0078d0" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep error_subcode | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TVer:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HamiVideo() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 "https://hamivideo.hinet.net/api/play.do?id=OTT_VOD_0000249064&freeProduct=1" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'code' | cut -f4 -d'"')
    if [[ "$checkfailed" == "06001-106" ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "06001-107" ]]; then
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Hami Video:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_4GTV() {
    local tmpresult=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sS --max-time 10 -X POST -d 'value=D33jXJ0JVFkBqV%2BZSi1mhPltbejAbPYbDnyI9hmfqjKaQwRQdj7ZKZRAdb16%2FRUrE8vGXLFfNKBLKJv%2BfDSiD%2BZJlUa5Msps2P4IWuTrUP1%2BCnS255YfRadf%2BKLUhIPj' "https://api2.4gtv.tv//Vod/GetVodUrl3" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    checkfailed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'Success' | awk '{print $2}' | cut -f1 -d',')
    if [[ "$checkfailed" == "false" ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$checkfailed" == "true" ]]; then
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r 4GTV.TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_SlingTV() {
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.sling.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sling TV:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_PlutoTV() {
    local tmpresult=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://pluto.tv/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'thanks-for-watching')
    if [ -n "$result" ]; then
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Pluto TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Pluto TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_HBOMax() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.hbomax.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isUnavailable=$(echo $tmpresult | grep 'geo-availability')
    local region=$(echo $tmpresult | cut -f4 -d"/" | tr [:lower:] [:upper:])
    if [ -n "$isUnavailable" ]; then
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isUnavailable" ] && [ -n "$region" ]; then
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$isUnavailable" ] && [ -z "$region" ]; then
        echo -n -e "\r HBO Max:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r HBO Max:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_MaxCom() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.max.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Max.com:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isUnavailable=$(echo $tmpresult | grep 'geo-availability')
    local region=$(echo $tmpresult | cut -f4 -d"/" | tr [:lower:] [:upper:])
    if [ -n "$isUnavailable" ]; then
        echo -n -e "\r Max.com:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isUnavailable" ] && [ -n "$region" ]; then
        echo -n -e "\r Max.com:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$isUnavailable" ] && [ -z "$region" ]; then
        echo -n -e "\r Max.com:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Max.com:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Channel4() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.channel4.com/simulcast/channels/C4" 2>&1)

    if [[ "$result" == "403" ]]; then
        echo -n -e "\r Channel 4:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "200" ]]; then
        echo -n -e "\r Channel 4:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 4:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ITVHUB() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://simulcast.itv.com/playlist/itvonline/ITV" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "404" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ITV Hub:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_iQYI_Region() {
    local tmpresult=$(curl $curlArgs -${1} -s -I --max-time 10 "https://www.iq.com/")

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$tmpresult" ]; then
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    result=$(echo "$tmpresult" | grep 'mod=' | awk '{print $2}' | cut -f2 -d'=' | cut -f1 -d';')

    if [ -n "$result" ]; then
        if [[ "$result" == "intl" ]]; then
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}No  (Intl)${Font_Suffix}\n"
        elif [[ "$result" == "ntw" ]]; then
            result=TW
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Green}Yes (Region: ${result})${Font_Suffix}\n"
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Green}Yes (Region: ${result})${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r iQyi Oversea:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_HuluUS() {
    if [[ "$1" == "4" ]]; then
        curl $curlArgs -fsL -o ./Hulu4.sh.x https://github.com/1-stream/RegionRestrictionCheck/raw/main/binary/Hulu4${arch}.sh.x >/dev/null 2>&1
        chmod +x ./Hulu4.sh.x
        ./Hulu4.sh.x >/dev/null 2>&1
    elif [[ "$1" == "6" ]]; then
        curl $curlArgs -fsL -o ./Hulu6.sh.x https://github.com/1-stream/RegionRestrictionCheck/raw/main/binary/Hulu6${arch}.sh.x >/dev/null 2>&1
        chmod +x ./Hulu6.sh.x
        ./Hulu6.sh.x >/dev/null 2>&1
    fi

    local result=$?

    if [[ "$result" == "1" ]]; then
        echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [[ "$result" == "0" ]]; then
        echo -n -e "\r Hulu:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result" == "10" ]]; then
        echo -n -e "\r Hulu:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
    rm -rf ./*.sh.x
}

function MediaUnlockTest_encoreTVB() {
    tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -H "Accept: application/json;pk=BCpkADawqM2Gpjj8SlY2mj4FgJJMfUpxTNtHWXOItY1PvamzxGstJbsgc-zFOHkCVcKeeOhPUd9MNHEGJoVy1By1Hrlh9rOXArC5M5MTcChJGU6maC8qhQ4Y8W-QYtvi8Nq34bUb9IOvoKBLeNF4D9Avskfe9rtMoEjj6ImXu_i4oIhYS0dx7x1AgHvtAaZFFhq3LBGtR-ZcsSqxNzVg-4PRUI9zcytQkk_YJXndNSfhVdmYmnxkgx1XXisGv1FG5GOmEK4jZ_Ih0riX5icFnHrgniADr4bA2G7TYh4OeGBrYLyFN_BDOvq3nFGrXVWrTLhaYyjxOr4rZqJPKK2ybmMsq466Ke1ZtE-wNQ" -H "Origin: https://www.encoretvb.com" "https://edge.api.brightcove.com/playback/v1/accounts/5324042807001/videos/6005570109001" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'error_subcode' | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'account_id' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r encoreTVB:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r encoreTVB:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Molotov() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://fapi.molotov.tv/v1/open-europe/is-france" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'false' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | python -m json.tool 2>/dev/null | grep 'true' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -n -e "\r Molotov:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Molotov:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Salto() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://geo.salto.fr/v1/geoInfo/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local CountryCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'country_code' | cut -f4 -d'"')
    local AllowedCode="FR,GP,MQ,GF,RE,YT,PM,BL,MF,WF,PF,NC"
    echo ${AllowedCode} | grep ${CountryCode} >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Salto:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_LineTV.TW() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://www.linetv.tw/api/part/11829/eps/1/part?chocomemberId=" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | awk '{print $2}' | cut -f1 -d',')
    if [ -n "$result" ]; then
        if [ "$result" = "228" ]; then
            echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        else
            echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r LineTV.TW:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Viu.com() {
    local tmpresult=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.viu.com/" 2>&1)
    if [ "$tmpresult" = "000" ]; then
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    result=$(echo $tmpresult | cut -f5 -d"/")
    if [ -n "$result" ]; then
        if [[ "$result" == "no-service" ]]; then
            echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            result=$(echo $result | tr [:lower:] [:upper:])
            echo -n -e "\r Viu.com:\t\t\t\t${Font_Green}Yes (Region: ${result})${Font_Suffix}\n"
            return
        fi

    else
        echo -n -e "\r Viu.com:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_Niconico() {
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 "https://www.nicovideo.jp/watch/so23017073" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Niconico:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    echo $tmpresult | grep '同じ地域' >/dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
        echo -n -e "\r Niconico:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Niconico:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_ParamountPlus() {
    local result=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.paramountplus.com/" 2>&1 | grep 'intl')

    if [ -n "$result" ]; then
        echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Paramount+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Paramount+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_KKTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api.kktv.me/v3/ipcheck" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'country' | cut -f4 -d'"')
    if [[ "$result" == "TW" ]]; then
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r KKTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_PeacockTV() {
    local tmpresult=$(curl $curlArgs -${1} -fsL -w "%{http_code}\n%{url_effective}\n" -o /dev/null "https://www.peacocktv.com/" 2>&1)
    if [[ "$tmpresult" == "000"* ]]; then
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'unavailable')
    if [ -n "$result" ]; then
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Peacock TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_FOD() {

    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://geocontrol1.stream.ne.jp/fod-geo/check.xml?time=1624504256" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    echo $tmpresult | grep 'true' >/dev/null 2>&1
    if [[ "$?" -eq 0 ]]; then
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r FOD(Fuji TV):\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_YouTube_Premium() {
    local tmpresult1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} --max-time 10 -sSL -H "Accept-Language: en" -b "YSC=BiCUU3-5Gdk; CONSENT=YES+cb.20220301-11-p0.en+FX+700; GPS=1; VISITOR_INFO1_LIVE=4VwPMkB7W5A; PREF=tz=Asia.Shanghai; _gcl_au=1.1.1809531354.1646633279" "https://www.youtube.com/premium" 2>&1)
    local tmpresult2=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} --max-time 10 -sSL -H "Accept-Language: en" "https://www.youtube.com/premium" 2>&1)
    local tmpresult="$tmpresult1:$tmpresult2"

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isCN=$(echo $tmpresult | grep 'www.google.cn')
    if [ -n "$isCN" ]; then
        echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} ${Font_Green} (Region: CN)${Font_Suffix} \n"
        return
    fi

    local region=$(echo $tmpresult | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')
    local isAvailable=$(echo $tmpresult | grep 'purchaseButtonOverride')
    local isAvailable2=$(echo $tmpresult | grep "Start trial")

    if [ -n "$isAvailable" ] || [ -n "$isAvailable2" ] || [ -n "$region" ]; then
        if [ -n "$region" ]; then
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        fi
    else
        if [ -n "$region" ]; then
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No  (Region: $region)${Font_Suffix} \n"
            return
        else
            echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}No${Font_Suffix} \n"
            return
        fi
    fi
    echo -n -e "\r YouTube Premium:\t\t\t${Font_Red}Failed${Font_Suffix}\n"

}

function MediaUnlockTest_YouTube_CDN() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://redirector.googlevideo.com/report_mapping" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r YouTube Region:\t\t\t${Font_Red}Check Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local iata=$(echo $tmpresult | grep router | cut -f2 -d'"' | cut -f2 -d"." | sed 's/.\{2\}$//' | tr [:lower:] [:upper:])
    local checkfailed=$(echo $tmpresult | grep "=>")
    if [ -z "$iata" ] && [ -n "$checkfailed" ]; then
        CDN_ISP=$(echo $checkfailed | awk '{print $3}' | cut -f1 -d"-" | tr [:lower:] [:upper:])
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Yellow}Associated with [$CDN_ISP]${Font_Suffix}\n"
        return
    elif [ -n "$iata" ]; then
        local lineNo=$(echo "$IATACode" | cut -f3 -d"|" | sed -n "/${iata}/=")
        local location=$(echo "$IATACode" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//')
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Green}$location${Font_Suffix}\n"
        return
    else
        echo -n -e "\r YouTube CDN:\t\t\t\t${Font_Red}Undetectable${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_BritBox() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.britbox.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r BritBox:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'locationnotsupported')
    if [ -n "$result" ]; then
        echo -n -e "\r BritBox:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r BritBox:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r BritBox:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_PrimeVideo_Region() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sL --max-time 10 "https://www.primevideo.com" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep '"currentTerritory":' | sed 's/.*currentTerritory//' | cut -f3 -d'"' | head -n 1)
    if [ -n "$result" ]; then
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Green}Yes (Region: $result)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Amazon Prime Video:\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Radiko() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://radiko.jp/area?_=1625406539531" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'class="OUT"')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'JAPAN')
    if [ -n "$checksuccess" ]; then
        area=$(echo $tmpresult | awk '{print $2}' | sed 's/.*>//')
        echo -n -e "\r Radiko:\t\t\t\t${Font_Green}Yes (City: $area)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Radiko:\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_DMM() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://api-p.videomarket.jp/v3/api/play/keyauth?playKey=4c9e93baa7ca1fc0b63ccf418275afc2&deviceType=3&bitRate=0&loginFlag=0&connType=" -H "X-Authorization: 2bCf81eLJWOnHuqg6nNaPZJWfnuniPTKz9GXv5IS" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'Access is denied')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'PlayKey has expired')
    if [ -n "$checksuccess" ]; then
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r DMM:\t\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_DMMTV() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST -d '{"player_name":"dmmtv_browser","player_version":"0.0.0","content_type_detail":"VOD_SVOD","content_id":"11uvjcm4fw2wdu7drtd1epnvz","purchase_product_id":null}' "https://api.beacon.dmm.com/v1/streaming/start" 2>&1)

    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local checkfailed=$(echo $tmpresult | grep 'FOREIGN')
    if [ -n "$checkfailed" ]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local checksuccess=$(echo $tmpresult | grep 'UNAUTHORIZED')
    if [ -n "$checksuccess" ]; then
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r DMM TV:\t\t\t\t${Font_Red}Unsupported${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Catchplay() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://sunapi.catchplay.com/geo" -H "authorization: Basic NTQ3MzM0NDgtYTU3Yi00MjU2LWE4MTEtMzdlYzNkNjJmM2E0Ok90QzR3elJRR2hLQ01sSDc2VEoy" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'code' | awk '{print $2}' | cut -f2 -d'"')
    region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'isoCode' | awk '{print $2}' | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [ "$result" = "0" ]; then
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
            return
        elif [ "$result" = "100016" ]; then
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r CatchPlay+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_HotStar() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.hotstar.com/o/v1/page/1557?offset=0&size=20&tao=0&tas=20" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "401" ]; then
        local region=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sI "https://www.hotstar.com" | grep 'geo=' | sed 's/.*geo=//' | cut -f1 -d",")
        local site_region=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.hotstar.com" | sed 's@.*com/@@' | tr [:lower:] [:upper:])
        if [ -n "$region" ] && [ "$region" = "$site_region" ]; then
            echo -n -e "\r HotStar:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
            return
        else
            echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    elif [ "$result" = "475" ]; then
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HotStar:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_LiTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 -X POST "https://www.litv.tv/vod/ajax/getUrl" -d '{"type":"noauth","assetId":"vod44868-010001M001_800K","puid":"6bc49a81-aad2-425c-8124-5b16e9e01337"}' -H "Content-Type: application/json" 2>&1)
    if [[ "$tmpresult" = "curl"* ]]; then
        echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'errorMessage' | awk '{print $2}' | cut -f1 -d"," | cut -f2 -d'"')
    if [ -n "$result" ]; then
        if [ "$result" = "null" ]; then
            echo -n -e "\r LiTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        elif [ "$result" = "vod.error.outsideregionerror" ]; then
            echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r LiTV:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_FuboTV() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://api.fubo.tv/appconfig/v1/homepage?platform=web&client_version=R20230310.2&nav=v0" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Forbidden IP')
    if [ -n "$result" ]; then
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Fubo TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Fox() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://x-live-fox-stgec.uplynk.com/ausw/slices/8d1/d8e6eec26bf544f084bad49a7fa2eac5/8d1de292bcc943a6b886d029e6c0dc87/G00000000.ts?pbs=c61e60ee63ce43359679fb9f65d21564&cloud=aws&si=0" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r FOX:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Joyn() {
    local tmpauth=$(curl $curlArgs -${1} -s --max-time 10 -X POST "https://auth.joyn.de/auth/anonymous" -H "Content-Type: application/json" -d '{"client_id":"b74b9f27-a994-4c45-b7eb-5b81b1c856e7","client_name":"web","anon_device_id":"b74b9f27-a994-4c45-b7eb-5b81b1c856e7"}' 2>&1)
    if [ -z "$tmpauth" ]; then
        echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    auth=$(echo $tmpauth | python -m json.tool 2>/dev/null | grep access_token | awk '{print $2}' | cut -f2 -d'"')
    local result=$(curl $curlArgs -s "https://api.joyn.de/content/entitlement-token" -H "x-api-key: 36lp1t4wto5uu2i2nk57ywy9on1ns5yg" -H "content-type: application/json" -d '{"content_id":"daserste-de-hd","content_type":"LIVE"}' -H "authorization: Bearer $auth" 2>&1)
    if [ -n "$result" ]; then
        isBlock=$(echo $result | python -m json.tool 2>/dev/null | grep 'code' | awk '{print $2}' | cut -f2 -d'"')
        if [[ "$isBlock" == "ENT_AssetNotAvailableInCountry" ]]; then
            echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            return
        else
            echo -n -e "\r Joyn:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            return
        fi
    else
        echo -n -e "\r Joyn:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_SKY_DE() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://edge.api.brightcove.com/playback/v1/accounts/1050888051001/videos/6247131490001" -H "Accept: application/json;pk=BCpkADawqM0OXCLe4eIkpyuir8Ssf3kIQAM62a1KMa4-1_vTOWQIxoHHD4-oL-dPmlp-rLoS-WIAcaAMKuZVMR57QY4uLAmP4Ov3V416hHbqr0GNNtzVXamJ6d4-rA3Xi98W-8wtypdEyjGEZNepUCt3D7UdMthbsG-Ean3V4cafT4nZX03st5HlyK1chp51SfA-vKcAOhHZ4_Oa9TTN61tEH6YqML9PWGyKrbuN5myICcGsFzP3R2aOF8c5rPCHT2ZAiG7MoavHx8WMjhfB0QdBr2fphX24CSpUKlcjEnQJnBiA1AdLg9iyReWrAdQylX4Eyhw5OwKiCGJznfgY6BDtbUmeq1I9r9RfmhP5bfxVGjILSEFZgXbMqGOvYdrdare0aW2fTCxeHdHt0vyKOWTC6CS1lrGJF2sFPKn1T1csjVR8s4MODqCBY1PTbHY4A9aZ-2MDJUVJDkOK52hGej6aXE5b9N9_xOT2B9wbXL1B1ZB4JLjeAdBuVtaUOJ44N0aCd8Ns0o02E1APxucQqrjnEociLFNB0Bobe1nkGt3PS74IQcs-eBvWYSpolldMH6TKLu8JqgdnM4WIp3FZtTWJRADgAmvF9tVDUG9pcJoRx_CZ4im-rn-AzN3FeOQrM4rTlU3Q8YhSmyEIoxYYqsFDwbFlhsAcvqQkgaElYtuciCL5i3U8N4W9rIhPhQJzsPafmLdWxBP_FXicyek25GHFdQzCiT8nf1o860Jv2cHQ4xUNcnP-9blIkLy9JmuB2RgUXOHzWsrLGGW6hq9wLUtqwEoxcEAAcNJgmoC0k8HE-Ga-NHXng6EFWnqiOg_mZ_MDd7gmHrrKLkQV" -H "Origin: https://www.sky.de" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Sky:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep error_subcode | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r Sky:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r Sky:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sky:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_ZDF() {
    # 测试，连续请求两次 (单独请求一次可能会返回35, 第二次开始变成0)
    local result=$(curl $curlArgs --user-agent "${UA_Dalvik}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://ssl.zdf.de/geo/de/geo.txt/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "404" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r ZDF: \t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_HBOGO_ASIA() {

    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api2.hbogoasia.com/v1/geog?lang=undefined&version=0&bundleId=www.hbogoasia.com" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep territory)
    if [ -z "$result" ]; then
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$result" ]; then
        local CountryCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep country | cut -f4 -d'"')
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Green}Yes (Region: $CountryCode)${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO GO Asia:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_EPIX() {
    tmpToken=$(curl $curlArgs -${1} -s -X POST --max-time 10 "https://api.epix.com/v2/sessions" -H "Content-Type: application/json" -d '{"device":{"guid":"e2add88e-2d92-4392-9724-326c2336013b","format":"console","os":"web","app_version":"1.0.2","model":"browser","manufacturer":"google"},"apikey":"f07debfcdf0f442bab197b517a5126ec","oauth":{"token":null}}' 2>&1)
    if [ -z "$tmpToken" ]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [[ "$tmpToken" == "error code"* ]]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    EpixToken=$(echo $tmpToken | python -m json.tool 2>/dev/null | grep 'session_token' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -X POST -s --max-time 10 "https://api.epix.com/v2/movies/16921/play" -d '{}' -H "X-Session-Token: $EpixToken" 2>&1)

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep status | cut -f4 -d'"')
    if [[ "$result" == "PROXY_DETECTED" ]]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "GEO_BLOCKED" ]]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "NOT_SUBSCRIBED" ]]; then
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Epix:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NLZIET() {
    TmpFallBackCode=$(curl $curlArgs -X GET -${1} -s --max-time 10 "https://id.nlziet.nl/connect/authorize/callback?client_id=triple-web&redirect_uri=https%3A%2F%2Fapp.nlziet.nl%2Fcallback&response_type=code&scope=openid%20api&state=91b508206f154b8381d3cc9061170527&code_challenge=EF_HpSX8a_leJOXmHqsYpBKjNRX0D8oZh_HfremhSWE&code_challenge_method=S256&response_mode=query" -b "optanonStatus=,C0001,; _gid=GA1.2.301664903.1627130663; OptanonConsent=isIABGlobal=false&datestamp=Sat+Jul+24+2021+20%3A44%3A23+GMT%2B0800+(%E9%A6%99%E6%B8%AF%E6%A0%87%E5%87%86%E6%97%B6%E9%97%B4)&version=6.17.0&hosts=&landingPath=https%3A%2F%2Fapp.nlziet.nl%2F&groups=C0001%3A1%2CC0002%3A0%2CC0003%3A0%2CC0004%3A0; _ga=GA1.2.1715247671.1627130661; _ga_LQL66TVRW1=GS1.1.1627130674.1.1.1627130679.0; _ga_QVB71SF0T8=GS1.1.1627130674.1.1.1627130679.0; .AspNetCore.Antiforgery.iEdXBvgZzA4=CfDJ8IdkGvI8o6RKkusMbm16dgZLQ3gjhTBrGZ5YAf7IYcvZ_uyXtvFmF8n87s9O1A6_hGU2cylV3fP7KrNnOndoMYFzeQTtFjYYe6rKr7G7tnvK5nDlZ1voXmUWbOynzDibE8HvkIICFkMzAZQksRtufiA; _ga_YV1B2GE80N=GS1.1.1627130661.1.1.1627130679.0; idsrv.session=3AF23B3FB60D818D8D6B519258D305C4; idsrv=CfDJ8IdkGvI8o6RKkusMbm16dgY4Sqm-8MQ1fT9qsFj38GA2PTr53t9IZNOTNbfRBqf4_2ymzxFOJr3WeVh_xbqM-yiQtvZ3LKdkZW8jR8g6jE9WeZj5kxdUZYSYRsOkUc-ZCQJA59txaiunIwwgwPfbRYW86mL_ZL_cTVZZldVNHswXPKvDKeeD9ieyXVGvLFEjgEUsNXzukaPN6SFuC0UISPcU8rqU9DdLp0y5QeoqE_z_nTlVgB65F-bGYeKtFVtk1uf7TYDgxnFeTJt5NpigsRk2zcIi0bmrzkgKd7oUQrAfVkUoy8T1-SnHAjN0VpDn4fRE4t1LdsU89IbV99pMVN2hvx5UrNT09lsSllkqzJXYoxC2dLQihWWcfH5J0lUn9GjFPTZWFOSw_6i164eYY2cpfvROcr3MJH0dXPf1kgLXNjN5ejjjCEPmgeMGvFdYS4cusx0tgvDp5R2hpbZGpRXneTgwAjFs9vgYuf_-r7cdb-fdSy-oohsdEDIIz5Zz_-7TvOl3hHEShAYaHjyUYWcm90E-6N3mjm7sBXUe9cDqbqbfpwgr1ciW0GbuZCqXaShrFvjE48EXnwt46TuBDAJJtVm4OZPE8ngJYscQrel7AJvm8tPpv10P6vw_Hva5IvCPxcLkyFj4xnbmY6hBU3-WQNawtZ67098QTEvMKgF44_QI0x5xP8NZ8HR2GDabLtMh88enklIB8_j7dp3RwoSLn9N61gZJWhBj9mU5FioAOGKsNJD4iWtPXKwUU0Yz4XnjD1KYL88BE3j7-Z5qiLQQGWj5GkKk7PLhPMA_PghLjE6KKKoWTny6NSXXyPSGZIHwlV2NGTH8EQmKoBq_xfejG-oBqSP0aCAf2apl6bwDHrBK3YVigLWPlej_4OKj7BC-KXhHxW7bNY4vHQ5EUHw" -I 2>&1 | grep Location | sed 's/.*callback?code=//' | cut -f1 -d"&")
    local tmpauth=$(curl $curlArgs -${1} -s --max-time 10 -X POST "https://id.nlziet.nl/connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=triple-web&code=${TmpFallBackCode}&redirect_uri=https%3A%2F%2Fapp.nlziet.nl%2Fcallback&code_verifier=04850de4083d48adb0bf6db3ebfd038fe27a7881de914b95a18d90ceb350316ed05a0e39e72440e6ace015ddc11d28b5&grant_type=authorization_code" 2>&1)

    if [ -z "$tmpauth" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

    local auth=$(echo $tmpauth | python -m json.tool 2>/dev/null | grep access_token | awk '{print $2}' | cut -f2 -d'"')
    local result=$(curl $curlArgs -X GET -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.nlziet.nl/v7/stream/handshake/Widevine/Dash/VOD/rJDaXnOP4kaRXnZdR_JofA?playerName=BitmovinWeb" -H "authorization: Bearer $auth" 2>&1)

    if [ "$result" = "000" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    elif [ "$result" = "500" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NLZIET:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_videoland() {
    local onetrustresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10 "https://geolocation.onetrust.com/cookieconsentpub/v1/geo/location/dnsfeed" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r videoland:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $onetrustresult | grep '"country":"NL"')
    if [ -z "$result" ]; then
        echo -n -e "\r videoland:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r videoland:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_NPO_Start_Plus() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://start-player.npo.nl/video/KN_1726624/streams?profile=dash-playready" -X POST 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isError=$(echo $tmpresult | grep 'locatie (33)')
    if [ -n "$isError" ]; then
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NPO Start Plus:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_RakutenTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://rakuten.tv" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'waitforit')
    if [ -n "$result" ]; then
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Rakuten TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_HBO_Spain() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api-discovery.hbo.eu/v1/discover/hbo?language=null&product=hboe" -H "X-Client-Name: web" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep signupAllowed | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Spain:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_PANTAYA() {
    local authorization=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://www.pantaya.com/sapi/header/v1/pantaya/us/735a16260c2b450686e68532ccd7f742" -H "Referer: https://www.pantaya.com/es/" 2>&1)
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://auth.pantaya.com/api/v4/User/geolocation" -H "AuthTokenAuthorization: $authorization")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r PANTAYA:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isAllowedAccess=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedAccess | awk '{print $2}' | cut -f1 -d",")
    local isAllowedCountry=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedCountry | awk '{print $2}' | cut -f1 -d",")
    local isKnownProxy=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isKnownProxy | awk '{print $2}' | cut -f1 -d",")
    if [[ "$isAllowedAccess" == "true" ]] && [[ "$isAllowedCountry" == "true" ]] && [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r PANTAYA:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$isAllowedAccess" == "false" ]]; then
        echo -n -e "\r PANTAYA:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r PANTAYA:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r PANTAYA:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Starz() {
    local authorization=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 "https://www.starz.com/sapi/header/v1/starz/us/09b397fc9eb64d5080687fc8a218775b" -H "Referer: https://www.starz.com/us/en/" 2>&1)
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://auth.starz.com/api/v4/User/geolocation" -H "AuthTokenAuthorization: $authorization")
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local isAllowedAccess=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedAccess | awk '{print $2}' | cut -f1 -d",")
    local isAllowedCountry=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowedCountry | awk '{print $2}' | cut -f1 -d",")
    local isKnownProxy=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isKnownProxy | awk '{print $2}' | cut -f1 -d",")
    if [[ "$isAllowedAccess" == "true" ]] && [[ "$isAllowedCountry" == "true" ]] && [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$isAllowedAccess" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$isKnownProxy" == "false" ]]; then
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Starz:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_CanalPlus() {
    local tmpresult=$(curl $curlArgs -${1} -sS -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://boutique-tunnel.canalplus.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Canal+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'othercountry')
    if [ -n "$result" ]; then
        echo -n -e "\r Canal+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Canal+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Canal+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_CBCGem() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://www.cbc.ca/g/stats/js/cbc-stats-top.js" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | sed 's/.*country":"//' | cut -f1 -d"}" | cut -f1 -d'"')
    if [[ "$result" == "CA" ]]; then
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r CBC Gem:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_AcornTV() {
    local tmpresult=$(curl $curlArgs -${1} -s -L --max-time 10 "https://acorn.tv/")
    local isblocked=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://acorn.tv/" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [[ "$isblocked" == "403" ]]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'Not yet available in your country')
    if [ -n "$result" ]; then
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Acorn TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Crave() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://capi.9c9media.com/destinations/crave_atexace/platforms/desktop/playback/contents/2189628/contentPackages/4178863/manifest.pmpd" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Geo Constraint Restrictions')
    if [ -n "$result" ]; then
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Crave:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Amediateka() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://www.amediateka.ru/" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'VPN')
    if [ -n "$result" ]; then
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Amediateka:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_MegogoTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://ctx.playfamily.ru/screenapi/v4/preparepurchase/web/1?elementId=0b974dc3-d4c5-4291-9df5-81a8132f67c5&elementAlias=51459024&elementType=GAME&withUpgradeSubscriptionReturnAmount=true&forceSvod=true&includeProductsForUpsale=false&sid=mDRnXOffdh_l2sBCyUIlbA" -H "X-SCRAPI-CLIENT-TS: 1627391624026" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep status | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "0" ]]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "502" ]]; then
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Megogo TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_RaiPlay() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://mediapolisvod.rai.it/relinker/relinkerServlet.htm?cont=VxXwi7UcqjApssSlashbjsAghviAeeqqEEqualeeqqEEqual&output=64" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'no_available')
    if [ -n "$result" ]; then
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Rai Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_TVBAnywhere() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://uapisfm.tvbanywhere.com.sg/geoip/check/platform/android" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'country' | awk '{print $2}' | head -1 | tr -d "," | tr -d "\"")
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'allow_in_this_country' | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}No  (Region: ${region})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TVBAnywhere+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_ProjectSekai() {
    local result=$(curl $curlArgs --user-agent "User-Agent: pjsekai/48 CFNetwork/1240.0.4 Darwin/20.6.0" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://game-version.sekai.colorfulpalette.org/1.8.1/3ed70b6a-8352-4532-b819-108837926ff5" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Project Sekai: Colorful Stage:\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KonosubaFD() {
    local result=$(curl $curlArgs -X POST --user-agent "User-Agent: pj0007/212 CFNetwork/1240.0.4 Darwin/20.6.0" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://api.konosubafd.jp/api/masterlist" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Konosuba Fantastic Days:\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_SHOWTIME() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.showtime.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SHOWTIME:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NBATV() {
    local tmpresult=$(curl $curlArgs -${1} -sSL --max-time 10 "https://www.nba.com/watch/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'Service is not available in your region')
    if [ -n "$result" ]; then
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NBA TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_ATTNOW() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.atttvnow.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Directv Stream:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_CineMax() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://play.maxgo.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r CineMax Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NetflixCDN() {
    if [[ "$1" == "6" ]]; then
        local nf_web_ip=$(dig www.netflix.com AAAA +noall +answer +nottl | grep -E "IN\s*AAAA" | awk '{print $4}' | head -1)
    else
        local nf_web_ip=$(dig www.netflix.com A +noall +answer +nottl | grep -E "IN\s*A" | awk '{print $4}' | head -1)
    fi
    if [ ! -n "$nf_web_ip" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Null${Font_Suffix}\n"
        return
    else
        local nf_web_isp=$(detect_isp $nf_web_ip)
        if [[ ! "$nf_web_isp" == *"Amazon"* ]] && [[ ! "$nf_web_isp" == *"Netflix"* ]]; then
            echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}Hijacked with [$nf_web_isp]${Font_Suffix}\n"
            return
        fi
    fi
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api.fast.com/netflix/speedtest/v2?https=true&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=1" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    elif [ -n "$(echo $tmpresult | grep '>403<')" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (IP Banned By Netflix)${Font_Suffix}\n"
        return
    fi

    local CDNAddr=$(echo $tmpresult | sed 's/.*"url":"//' | cut -f3 -d"/")
    if [[ "$1" == "6" ]]; then
        nslookup -q=AAAA $CDNAddr >~/v6_addr.txt
        ifAAAA=$(cat ~/v6_addr.txt | grep 'AAAA address' | awk '{print $NF}')
        if [ -z "$ifAAAA" ]; then
            CDNIP=$(cat ~/v6_addr.txt | grep Address | sed -n '$p' | awk '{print $NF}')
        else
            CDNIP=${ifAAAA}
        fi
    else
        CDNIP=$(nslookup $CDNAddr | sed '/^\s*$/d' | awk 'END {print}' | awk '{print $2}')
    fi

    if [ -z "$CDNIP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}Failed (CDN IP Not Found)${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi

    local CDN_ISP=$(curl $curlArgs --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$CDNIP" 2>&1 | python -m json.tool 2>/dev/null | grep 'isp' | cut -f4 -d'"')
    local iata=$(echo $CDNAddr | cut -f3 -d"-" | sed 's/.\{3\}$//' | tr [:lower:] [:upper:])

    local IATACode2=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/reference/IATACode2.txt" 2>&1)

    local isIataFound1=$(echo "$IATACode" | grep $iata)
    local isIataFound2=$(echo "$IATACode2" | grep $iata)

    if [ -n "$isIataFound1" ]; then
        local lineNo=$(echo "$IATACode" | cut -f3 -d"|" | sed -n "/${iata}/=")
        local location=$(echo "$IATACode" | awk "NR==${lineNo}" | cut -f1 -d"|" | sed -e 's/^[[:space:]]*//')
    elif [ -z "$isIataFound1" ] && [ -n "$isIataFound2" ]; then
        local lineNo=$(echo "$IATACode2" | awk '{print $1}' | sed -n "/${iata}/=")
        local location=$(echo "$IATACode2" | awk "NR==${lineNo}" | cut -f2 -d"," | sed -e 's/^[[:space:]]*//' | tr [:upper:] [:lower:] | sed 's/\b[a-z]/\U&/g')
    fi

    if [ -n "$location" ] && [[ "$CDN_ISP" == "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Green}$location ${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [[ "$CDN_ISP" != "Netflix Streaming Services" ]]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Yellow}Associated with [$CDN_ISP] in [$location]${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    elif [ -n "$location" ] && [ -z "$CDN_ISP" ]; then
        echo -n -e "\r Netflix Preferred CDN:\t\t\t${Font_Red}No ISP Info Founded${Font_Suffix}\n"
        rm -rf ~/v6_addr.txt
        return
    fi
}

function MediaUnlockTest_HBO_Nordic() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api-discovery.hbo.eu/v1/discover/hbo?language=null&product=hbon" -H "X-Client-Name: web" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep signupAllowed | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Nordic:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_HBO_Portugal() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://api.ugw.hbogo.eu/v3.0/GeoCheck/json/PRT" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep allow | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "1" ]]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "0" ]]; then
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r HBO Portugal:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SkyGo() {
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://skyid.sky.com/authorise/skygo?response_type=token&client_id=sky&appearance=compact&redirect_uri=skygo://auth" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep "You don't have permission to access")
    if [ -z "$result" ]; then
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sky Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_StarPlus() {
    local starcontent=$(echo "$Media_Cookie" | sed -n '10p')
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://star.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: c3RhciZicm93c2VyJjEuMC4w.COknIGCR7I6N0M5PGnlcdbESHGkNv7POwhFNL-_vIdg" -d "$starcontent" 2>&1 )
    local previewcheck=$(curl $curlArgs -${1} -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.starplus.com/login" 2>&1)
    local isUnavailable=$(echo $previewcheck | grep unavailable)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Star+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [ -n "$region" ] && [ -z "$isUnavailable" ] && [[ "$inSupportedLocation" == "false" ]]; then
        echo -n -e "\r Star+:\t\t\t\t\t${Font_Yellow}CDN Relay Available${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [ -n "$isUnavailable" ]; then
        echo -n -e "\r Star+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$region" ] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r Star+:\t\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    elif [ -z "$region" ]; then
        echo -n -e "\r Star+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_DirecTVGO() {
    local tmpresult=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.directvgo.com/registrarse" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isForbidden=$(echo $tmpresult | grep 'proximamente')
    local region=$(echo $tmpresult | cut -f4 -d"/" | tr [:lower:] [:upper:])
    if [ -n "$isForbidden" ]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isForbidden" ] && [ -n "$region" ]; then
        echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r DirecTV Go:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_DAM() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "http://cds1.clubdam.com/vhls-cds1/site/xbox/sample_1.mp4.m3u8" 2>&1)
    if [[ "$result" == "000" ]]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Karaoke@DAM:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_DiscoveryPlus() {
    local GetToken=$(curl $curlArgs -${1} -sS "https://us1-prod-direct.discoveryplus.com/token?deviceId=d1a4a5d25212400d1e6985984604d740&realm=go&shortlived=true" 2>&1)
    if [[ "$GetToken" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetToken" == "curl"* ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $GetToken | python -m json.tool 2>/dev/null | grep '"token":' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -sS "https://us1-prod-direct.discoveryplus.com/users/me" -b "_gcl_au=1.1.858579665.1632206782; _rdt_uuid=1632206782474.6a9ad4f2-8ef7-4a49-9d60-e071bce45e88; _scid=d154b864-8b7e-4f46-90e0-8b56cff67d05; _pin_unauth=dWlkPU1qWTRNR1ZoTlRBdE1tSXdNaTAwTW1Nd0xUbGxORFV0WWpZMU0yVXdPV1l6WldFeQ; _sctr=1|1632153600000; aam_fw=aam%3D9354365%3Baam%3D9040990; aam_uuid=24382050115125439381416006538140778858; st=${Token}; gi_ls=0; _uetvid=a25161a01aa711ec92d47775379d5e4d; AMCV_BC501253513148ED0A490D45%40AdobeOrg=-1124106680%7CMCIDTS%7C18894%7CMCMID%7C24223296309793747161435877577673078228%7CMCAAMLH-1633011393%7C9%7CMCAAMB-1633011393%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1632413793s%7CNONE%7CvVersion%7C5.2.0; ass=19ef15da-95d6-4b1d-8fa2-e9e099c9cc38.1632408400.1632406594" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep currentLocationTerritory | cut -f4 -d'"')
    if [[ "$result" == "us" ]]; then
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Discovery+:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ESPNPlus() {
    local espncookie=$(echo "$Media_Cookie" | sed -n '11p')
    local TokenContent=$(curl -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://espn.api.edge.bamgrid.com/token" -H "authorization: Bearer ZXNwbiZicm93c2VyJjEuMC4w.ptUt7QxsteaRruuPmGZFaJByOoqKvDP2a5YkInHrc7c" -d "$espncookie" 2>&1)
    local isBanned=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'forbidden-location')
    local is403=$(echo $TokenContent | grep '403 ERROR')

    if [ -n "$isBanned" ] || [ -n "$is403" ]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    local fakecontent=$(echo "$Media_Cookie" | sed -n '10p')
    local refreshToken=$(echo $TokenContent | python -m json.tool 2>/dev/null | grep 'refresh_token' | awk '{print $2}' | cut -f2 -d'"')
    local espncontent=$(echo $fakecontent | sed "s/ILOVESTAR/${refreshToken}/g")
    local tmpresult=$(curl -${1} --user-agent "${UA_Browser}" -X POST -sSL --max-time 10 "https://espn.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZXNwbiZicm93c2VyJjEuMC4w.ptUt7QxsteaRruuPmGZFaJByOoqKvDP2a5YkInHrc7c" -d "$espncontent" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'countryCode' | cut -f4 -d'"')
    local inSupportedLocation=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'inSupportedLocation' | awk '{print $2}' | cut -f1 -d',')

    if [[ "$region" == "US" ]] && [[ "$inSupportedLocation" == "true" ]]; then
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ESPN+:${Font_SkyBlue}[Sponsored by Jam]${Font_Suffix}\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Stan() {
    local tmpresult=$(curl $curlArgs -${1} -X POST -sS --max-time 10 "https://api.stan.com.au/login/v1/sessions/web/account" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep VPNDetected)
    if [ -z "$result" ]; then
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Stan:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Binge() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://auth.streamotion.com.au" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ] || [ "$result" = "302" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Binge:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Docplay() {
    local result=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.docplay.com/subscribe" 2>&1 | grep 'geoblocked')
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Docplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        isKayoSportsOK=2
        return
    elif [ -n "$result" ]; then
        echo -n -e "\r Docplay:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        isKayoSportsOK=0
        return
    else
        echo -n -e "\r Docplay:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        isKayoSportsOK=1
        return
    fi

    echo -n -e "\r Docplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    isKayoSportsOK=2
    return

}

function MediaUnlockTest_OptusSports() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://sport.optus.com.au/api/userauth/validate/web/username/restriction.check@gmail.com" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Optus Sports:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_KayoSports() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://auth.streamotion.com.au" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ] || [ "$result" = "302" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Kayo Sports:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_NeonTV() {
    local NeonHeader=$(echo "$Media_Cookie" | sed -n '12p')
    local NeonContent=$(echo "$Media_Cookie" | sed -n '13p')
    local tmpresult=$(curl $curlArgs -${1} -sS -X POST "https://api.neontv.co.nz/api/client/gql?" -H "content-type: application/json" -H "$NeonHeader" -d "$NeonContent" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'RESTRICTED_GEOLOCATION')
    if [ -z "$result" ]; then
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Neon TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SkyGONZ() {
    local result=$(curl $curlArgs -${1} -fs --write-out %{http_code} --output /dev/null --max-time 10 "https://login.sky.co.nz/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "302" ]; then
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SkyGo NZ:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_ThreeNow() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://bravo-livestream.fullscreen.nz/index.m3u8" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ThreeNow:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_MaoriTV() {
    local tmpresult=$(curl $curlArgs -${1} -s --max-time 10 "https://edge.api.brightcove.com/playback/v1/accounts/1614493167001/videos/6275380737001" -H "Accept: application/json;pk=BCpkADawqM2E9yW4lLgKIEIV5majz5djzZCIqJiYMkP5yYaYdF6AQYq4isPId1ZLtQdGnK1ErLYG0-r1N-3DzAEdbfvw9SFdDWz_i09pLp8Njx1ybslyIXid-X_Dx31b7-PLdQhJCws-vk6Y" -H "Origin: https://www.maoritelevision.com" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep error_subcode | cut -f4 -d'"')
    if [[ "$result" == "CLIENT_GEO" ]]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$result" ] && [ -n "$tmpresult" ]; then
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Maori TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_SBSonDemand() {

    local tmpresult=$(curl $curlArgs -${1} -sS "https://www.sbs.com.au/api/v3/network?context=odwebsite" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep country_code | cut -f4 -d'"')
    if [[ "$result" == "AU" ]]; then
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r SBS on Demand:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_ABCiView() {
    local tmpresult=$(curl $curlArgs -${1} -sS --max-time 10 "https://api.iview.abc.net.au/v2/show/abc-kids-live-stream/video/LS1604H001S00?embed=highlightVideo,selectedSeries" 2>&1)
    if [ -z "$tmpresult" ]; then
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'unavailable outside Australia')
    if [ -z "$result" ]; then
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r ABC iView:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Channel9() {
    local result=$(curl $curlArgs -${1} -Ss -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://login.nine.com.au" 2>&1 | grep 'geoblock')
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -n "$result" ]; then
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Channel 9:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 9:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Telasa() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://api-videopass-anon.kddi-video.com/v1/playback/system_status" -H "X-Device-ID: d36f8e6b-e344-4f5e-9a55-90aeb3403799" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local isForbidden=$(echo $tmpresult | grep IPLocationNotAllowed)
    local isAllowed=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"type"' | cut -f4 -d'"')
    if [ -n "$isForbidden" ]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -z "$isForbidden" ] && [[ "$isAllowed" == "OK" ]]; then
        echo -n -e "\r Telasa:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Telasa:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_SetantaSports() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://dce-frontoffice.imggaming.com/api/v2/consent-prompt" -H "Realm: dce.adjara" -H "x-api-key: 857a1e5d-e35e-4fdf-805b-a87b6f8364bf" 2>&1)
    local tmpresult1=$(curl $curlArgs -${1} -sS "https://dce-frontoffice.imggaming.com/api/v3/i18n/country-codes" -H "Realm: dce.adjara" -H "x-api-key: 857a1e5d-e35e-4fdf-805b-a87b6f8364bf" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep outsideAllowedTerritories | awk '{print $2}' | cut -f1 -d",")
    local region=$(echo $tmpresult1 | python -m json.tool 2>/dev/null | grep callerCountryCode | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}No  (Region: ${region})${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r Setanta Sports:\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Setanta Sports:\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_MolaTV() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://mola.tv/api/v2/videos/geoguard/check/vd30491025" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep isAllowed | awk '{print $2}')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Mola TV:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_BeinConnect() {
    local result=$(curl $curlArgs -${1} -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://proxies.bein-mena-production.eu-west-2.tuc.red/proxy/availableOffers" 2>&1)
    if [ "$result" = "000" ] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [ "$result" = "000" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "500" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "451" ]; then
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Bein Sports Connect:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_EurosportRO() {
    local tmpresult=$(curl $curlArgs -${1} -sS "https://eu3-prod-direct.eurosport.ro/playback/v2/videoPlaybackInfo/sourceSystemId/eurosport-vid1560178?usePreAuth=true" -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJVU0VSSUQ6ZXVyb3Nwb3J0OjlkMWU3MmYyLTdkYjItNDE2Yy1iNmIyLTAwZjQyMWRiN2M4NiIsImp0aSI6InRva2VuLTc0MDU0ZDE3LWFhNWUtNGI0ZS04MDM4LTM3NTE4YjBiMzE4OCIsImFub255bW91cyI6dHJ1ZSwiaWF0IjoxNjM0NjM0MzY0fQ.T7X_JOyvAr3-spU_6wh07re4W-fmbCxZdGaUSZiu1mw' 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep access.denied.geoblocked)
    if [ -n "$result" ]; then
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Eurosport RO:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_DiscoveryPlusUK() {
    local GetToken=$(curl $curlArgs -${1} -sS "https://disco-api.discoveryplus.co.uk/token?realm=questuk&deviceId=61ee588b07c4df08c02861ecc1366a592c4ad02d08e8228ecfee67501d98bf47&shortlived=true" 2>&1)
    if [[ "$GetToken" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetToken" == "curl"* ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $GetToken | python -m json.tool 2>/dev/null | grep '"token":' | cut -f4 -d'"')
    local tmpresult=$(curl $curlArgs -${1} -sS "https://disco-api.discoveryplus.co.uk/users/me" -b "st=${Token}" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep currentLocationTerritory | cut -f4 -d'"')
    if [[ "$result" == "gb" ]]; then
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Discovery+ UK:\t\t\t\t${Font_Red}Failed ${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Channel5() {
    local Timestamp=$(date +%s)
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://cassie.channel5.com/api/v2/live_media/my5desktopng/C5.json?timestamp=${Timestamp}&auth=0_rZDiY0hp_TNcDyk2uD-Kl40HqDbXs7hOawxyqPnbI" 2>&1)
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep code | cut -f4 -d'"')
    if [ -z "$result" ] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [[ "$result" == "4003" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ -n "$result" ] && [[ "$result" != "4003" ]]; then
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Channel 5:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_MyVideo() {
    local tmpresult=$(curl $curlArgs -${1} -SsL -o /dev/null --max-time 10 -w '%{url_effective}\n' "https://www.myvideo.net.tw/login.do" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result=$(echo $tmpresult | grep 'serviceAreaBlock')
    if [ -n "$result" ]; then
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MyVideo:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MyVideo:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_7plus() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://7plus-sevennetwork.akamaized.net/media/v1/dash/live/cenc/5303576322001/68dca38b-85d7-4dae-b1c5-c88acc58d51c/f4ea4711-514e-4cad-824f-e0c87db0a614/225ec0a0-ef18-4b7c-8fd6-8dcdd16cf03a/1x/segment0.m4f?akamai_token=exp=1672500385~acl=/media/v1/dash/live/cenc/5303576322001/68dca38b-85d7-4dae-b1c5-c88acc58d51c/f4ea4711-514e-4cad-824f-e0c87db0a614/*~hmac=800e1e1d1943addf12b71339277c637c7211582fe12d148e486ae40d6549dbde" 2>&1)
    if [[ "$GetPlayURL" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$GetPlayURL" == "curl"* ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r 7plus:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

}

function MediaUnlockTest_Channel10() {
    local tmpresult=$(curl $curlArgs -${1} -sL --max-time 10 "https://e410fasadvz.global.ssl.fastly.net/geo" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'allow' | awk '{print $2}' | cut -f1 -d",")
    if [[ "$result" == "false" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [[ "$result" == "true" ]]; then
        echo -n -e "\r Channel 10:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Channel 10:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    return

}

function MediaUnlockTest_Funimation() {
    if [ "$is_busybox" == 1 ]; then
        tmp_file=$(mktemp)
    else
        tmp_file=$(mktemp --suffix=RRC)
    fi

    curl $curlArgs -${1} --user-agent "${UA_Browser}" -ILs --max-time 10 --insecure "https://www.funimation.com" >${tmp_file}
    result=$(cat ${tmp_file} | awk 'NR==1' | awk '{print $2}')
    isHasRegion=$(cat ${tmp_file} | grep 'region=')
    if [[ "$1" == "6" ]]; then
        echo -n -e "\r Funimation:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [ "$result" = "000" ]; then
        echo -n -e "\r Funimation:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Funimation:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ -n "$isHasRegion" ]; then
        local region=$(cat ${tmp_file} | grep region= | awk '{print $2}' | cut -f1 -d";" | cut -f2 -d"=")
        echo -n -e "\r Funimation:\t\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Funimation:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Spotify() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -s --max-time 10 -X POST "https://spclient.wg.spotify.com/signup/public/v1/account" -d "birth_day=11&birth_month=11&birth_year=2000&collect_personal_info=undefined&creation_flow=&creation_point=https%3A%2F%2Fwww.spotify.com%2Fhk-en%2F&displayname=Gay%20Lord&gender=male&iagree=1&key=a1e486e2729f46d6bb368d6b2bcda326&platform=www&referrer=&send-email=0&thirdpartyemail=0&identifier_token=AgE6YTvEzkReHNfJpO114514" -H "Accept-Language: en" 2>&1)
    local region=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"country":' | cut -f4 -d'"')
    local isLaunched=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep is_country_launched | cut -f1 -d',' | awk '{print $2}')
    local StatusCode=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep status | cut -f1 -d',' | awk '{print $2}')

    if [ "$tmpresult" = "000" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$StatusCode" = "320" ] || [ "$StatusCode" = "120" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    elif [ "$StatusCode" = "311" ] && [ "$isLaunched" = "true" ]; then
        echo -n -e "\r Spotify Registration:\t\t\t${Font_Green}Yes (Region: $region)${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Spotify Registration:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_VideoMarket() {
    local TokenSrc=$(curl $curlArgs  --user-agent "${UA_Browser}" -${1} -Ss --max-time 10 "https://www.videomarket.jp/player/17588S/A17588S001999H01"  2>&1)
    if [[ "$TokenSrc" == "curl"* ]]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local Token=$(echo $TokenSrc| grep -Eo 'notLoggedInTokenPc:(.|)*notLoggedInTokenSpAndroid')
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --max-time 10 "https://www.videomarket.jp/graphql" -X POST -d '{"operationName":"readStatus","variables":{},"query":"query readStatus {\n  readStatus {\n    isRead\n    __typename\n  }\n}\n"}' -H "Authorization:Bearer ${Token:20:-27}"   2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep OverseasAccess)
    if [ -n "$result" ]; then
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r VideoMarket:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_J:COM_ON_DEMAND() {
	local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://id.zaq.ne.jp" 2>&1)
	if [ "$result" = "000" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "502" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r J:com On Demand:\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_music.jp() {
	local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sL --max-time 10 "https://overseaauth.music-book.jp/globalIpcheck.js" 2>&1)
	if [ -n "$result" ]; then
        echo -n -e "\r music.jp:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r music.jp:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Instagram.Music() {
    local cookie=$(echo "$Media_Cookie" | sed -n '14p')
    local result=$(curl $curlArgs -${1} -s --user-agent "${UA_Browser}" --max-time 10 -H "X-IG-App-ID: 936619743392459" -H "X-IG-WWW-Claim: 0" -b "$cookie" "https://i.instagram.com/api/v1/media/2924384735484795396/info/" 2>&1 | python -m json.tool 2>/dev/null | grep '"should_mute_audio"' | awk '{print $2}' | cut -f1 -d',')
    echo -n -e " Instagram Licensed Music:\t\t->\c"
    if [[ "$result" == "false" ]]; then
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result" == "true" ]]; then
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Instagram Licensed Music:\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi

}

function MediaUnlockTest_Popcornflix(){
    local result=$(curl $curlArgs -${1} -s --user-agent "${UA_Browser}" --write-out %{http_code} --output /dev/null --max-time 10 "https://popcornflix-prod.cloud.seachange.com/cms/popcornflix/clientconfiguration/versions/2" 2>&1)
    if [ "$result" = "000" ] && [ "$1" == "6" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
    elif [ "$result" = "000" ] && [ "$1" == "4" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Popcornflix:\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_TubiTV(){
    local tmpresult=$(curl $curlArgs -${1} -sSL --user-agent "${UA_Browser}" -w "%{url_effective}\n" -o /dev/null  --max-time 10 "https://tubitv.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'gdpr.tubi.tv')
    if [ -n "$result" ]; then
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Tubi TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Philo(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://content-us-east-2-fastly-b.www.philo.com/geo" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"status":' | cut -f1 -d',' | awk '{print $2}' | sed 's/"//g')
    if [[ "$result" == 'FAIL' ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [[ "$result" == 'SUCCESS' ]]; then
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Philo:\t\t\t\t\t${Font_Green}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_FXNOW(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://fxnow.fxnetworks.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'is not accessible')
    if [ -n "$result" ]; then
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r FXNOW:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Crunchyroll(){
    local tmpresult=$(curl $curlArgs -${1} -fsSL --user-agent "${UA_Browser}" --max-time 10 "https://c.evidon.com/geo/country.js" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep "'code':'us'")
    if [ -z "$result" ]; then
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Crunchyroll:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}


function MediaUnlockTest_CWTV(){
    local result=$(curl $curlArgs -${1} -fsL --user-agent "${UA_Browser}" --write-out %{http_code} --output /dev/null --max-time 10 --retry 3 "https://www.cwtv.com/" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    elif [ "$result" = "403" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [ "$result" = "200" ]; then
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r CW TV:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Shudder(){
    local tmpresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10 "https://www.shudder.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Shudder:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'not available')
    if [ -n "$result" ]; then
        echo -n -e "\r Shudder:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Shudder:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_TLCGO(){
    onetrustresult=$(curl $curlArgs -${1} -sS --user-agent "${UA_Browser}" --max-time 10 "https://geolocation.onetrust.com/cookieconsentpub/v1/geo/location/dnsfeed" 2>&1)
    if [ "$1" == "6" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$onetrustresult" == "curl"* ]]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$onetrustresult" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $onetrustresult | grep '"country":"US"')
    if [ -z "$result" ]; then
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r TLC GO:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Wavve() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://apis.wavve.com/fz/streaming?device=pc&partner=pooq&apikey=E5F3E0D30947AA5440556471321BB6D9&credential=none&service=wavve&pooqzone=none&region=kor&drm=pr&targetage=all&contentid=MV_C3001_C300000012559&contenttype=movie&hdr=sdr&videocodec=avc&audiocodec=ac3&issurround=n&format=normal&withinsubtitle=n&action=dash&protocol=dash&quality=auto&deviceModelId=Windows%2010&guid=1a8e9c88-6a3b-11ed-8584-eed06ef80652&lastplayid=none&authtype=cookie&isabr=y&ishevc=n" 2>&1)
    if [[ "$result1" == "000" ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Wavve:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Tving() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://api.tving.com/v2a/media/stream/info?apiKey=1e7952d0917d6aab1f0293a063697610&mediaCode=RV60891248" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep 'play')
    if [ -z "$result1" ]; then
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Tving:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_CoupangPlay() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsI --max-time 10 "https://www.coupangplay.com/" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep 'Location' -i | awk '{print $2}' )
    if [[ "$result1" == *"/not-available"* ]]; then
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Coupang Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NaverTV() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://tv.naver.com/v/31030608" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep 'nation_error' | grep 'display:none' )
    if [ -z "$result1" ]; then
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r Naver TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Afreeca() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.afreecatv.com/player/97464151" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "document.location.href='https://vod.afreecatv.com'" )
    if [ -z "$result1" ]; then
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Afreeca TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KBSDomestic() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.kbs.co.kr/index.html?source=episode&sname=vod&stype=vod&program_code=T2022-0690&program_id=PS-2022164275-01-000&broadcast_complete_yn=N&local_station_code=00&section_code=03" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "ipck" | grep 'Domestic\\\":true' )
    if [ -z "$result1" ]; then
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r KBS Domestic:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KBSAmerican() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsL --max-time 10 "https://vod.kbs.co.kr/index.html?source=episode&sname=vod&stype=vod&program_code=T2022-0690&program_id=PS-2022164275-01-000&broadcast_complete_yn=N&local_station_code=00&section_code=03 " 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep "ipck" | grep 'American\\\":true' )
    if [ -z "$result1" ]; then
        echo -n -e "\r KBS American:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r KBS American:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_KOCOWA() {
    local result1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.kocowa.com/" 2>&1)
    if [[ "$result1" == "000" ]] && [ "$1" == "6" ]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result1" == "000" ]]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "200" ]]; then
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r KOCOWA:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NBCTV(){
    if [[ "$onetrustresult" == "curl"* ]]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$onetrustresult" ]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $onetrustresult | grep '"country":"US"')
    if [ -z "$result" ]; then
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r NBC TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_Crackle(){
    local tmpresult=$(curl $curlArgs -${1} -sS -I --user-agent "${UA_Browser}" --max-time 10 "https://prod-api.crackle.com/appconfig" 2>&1 | grep -E 'x-crackle-region:|curl')
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ -z "$tmpresult" ]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | awk '{print $2}' | sed 's/[[:space:]]//g')
    if [[ "$result" == "US" ]]; then
        echo -n -e "\r Crackle:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    else
        echo -n -e "\r Crackle:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_AETV(){
    local tmpresult=$(curl $curlArgs -${1} -sS -X POST --user-agent "${UA_Browser}" --max-time 10 "https://ccpa-service.sp-prod.net/ccpa/consent/10265/display-dns" 2>&1)
    if [[ "$tmpresult" == "curl"* ]] && [ "$1" == "6" ]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | python -m json.tool 2>/dev/null | grep '"ccpaApplies":' | cut -f1 -d',' | awk '{print $2}')
    if [[ "$result" == "true" ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    elif [[ "$result" == "false" ]]; then
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r A&E TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_NFLPlus() {
    local tmpresult=$(curl $curlArgs -${1} -fsL -w "%{http_code}\n%{url_effective}\n" -o /dev/null "https://www.nfl.com/plus/" 2>&1)
    if [[ "$tmpresult" == "000"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult" == "000"* ]]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo $tmpresult | grep 'nflgamepass')
    if [ -n "$result" ]; then
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        echo -n -e "\r NFL+:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_SkyShowTime(){
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fSsi --max-time 10 "https://www.skyshowtime.com/" -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result1=$(echo "$tmpresult" | grep 'location' | head -1 | awk '{print $2}' )
    if [[ "$result1" == *"where-can-i-stream"* ]]; then
    	echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(echo -n "$result1" | sed 's#https://www.skyshowtime.com/\([0-9a-zA-Z][0-9a-zA-Z]\)?\r#\1#i' | tr [:lower:] [:upper:] )
        echo -n -e "\r SkyShowTime:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi
}

function MediaUnlockTest_MathsSpot() {
    local tmpresult1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://netv2.now.gg/v3/playtoken" 2>&1)
    if [[ "$tmpresult1" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$tmpresult1" == "curl"* ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local blocked=$(echo "$tmpresult1" | grep 'Request blocked')
    if [ -n "$blocked" ]; then
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}No  (Proxy/VPN Detected)${Font_Suffix}\n"
        return
    fi
    local playtoken=$(echo "$tmpresult1" | python -m json.tool 2>/dev/null | grep '"playToken":' | awk '{print $2}' | cut -f2 -d'"')
    local region=$(echo "$tmpresult1" | python -m json.tool 2>/dev/null | grep '"countryCode":' | awk '{print $2}' | cut -f2 -d'"')
    local host=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://mathsspot.com/2/api/play/v1/startSession?uaId=ua-KzV6fgcCBHQDU9DHCt2uG&uaSessionId=uasess-IdEux1e80EUstUlnnnHG0&appId=5349&initialOrientation=landscape&utmSource=NA&utmMedium=NA&utmCampaign=NA&deviceType=&playToken=${playtoken}&deepLinkUrl=&accessCode=" 2>&1)
    local tmpresult2=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sS --max-time 10 "https://mathsspot.com/2/api/play/v1/startSession?uaId=ua-KzV6fgcCBHQDU9DHCt2uG&uaSessionId=uasess-IdEux1e80EUstUlnnnHG0&appId=5349&initialOrientation=landscape&utmSource=NA&utmMedium=NA&utmCampaign=NA&deviceType=&playToken=${playtoken}&deepLinkUrl=&accessCode=" -H "x-ngg-fe-version: ${host}" 2>&1)
    if [[ "$host" == "curl"* ]] || [[ "$tmpresult2" == "curl"* ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result=$(echo "$tmpresult2" | python -m json.tool 2>/dev/null | grep '"status":' | awk '{print $2}' | cut -f2 -d'"')
    if [[ "$result" == "FailureServiceNotInRegion" ]]; then
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    elif [[ "$result" == "Success" ]]; then
        echo -n -e "\r Maths Spot:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
    else
    	echo -n -e "\r Maths Spot:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
    fi
}

function MediaUnblockTest_BGlobalSEA() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=347666" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global SouthEastAsia:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalTH() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=10077726" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Thailand Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalID() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=11130043" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Indonesia Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnblockTest_BGlobalVN() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.tv/intl/gateway/web/playurl?s_locale=en_US&platform=web&ep_id=11405745" 2>&1)
    local result1="$(echo "${result}" | python -m json.tool 2>/dev/null | grep '"code"' | head -1 | awk '{print $2}' | cut -d ',' -f1)"
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == "0" ]]; then
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r B-Global Việt Nam Only:\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_AISPlay() {
    local result=$(curl $curlArgs -${1} -sSLI --max-time 10 "https://49-231-37-237-rewriter.ais-vidnt.com/ais/play/origin/VOD/playlist/ais-yMzNH1-bGUxc/index.m3u8" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | grep 'X-Geo-Protection-System-Status' | awk '{print $2}' )"
    if [[ "$result1" == *"ALLOW"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [[ "$result1" == *"BLOCK"* ]]; then
        echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r AIS Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_TrueID() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://movie.trueid.net/apis/auth/checkedplay" -X POST -d '{"lang":"th","cmsId":"gROjxLzNBJb6","contentType":"movie"}' -H "Authorization: Basic YmJjNjI5Yzk3OTEzMDNhMmNjYzcyMWQzYTJlNGRkOGFiZWZkN2ZhNzoxMzAzYTJjY2M3MjFkM2EyZTRkZDhhYmVmZDdmYTc=" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep 'billboardType' | awk '{print $2}' )"
    if [[ "$result1" == *"GEO_BLOCK"* ]]; then
        echo -n -e "\r TrueID:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r TrueID:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r TrueID:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_meWATCH() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://cdn.mewatch.sg/api/items/362414/videos?delivery=stream%2Cprogressive&ff=idp%2Cldp%2Crpt%2Ccd&lang=en&resolution=External&segments=all" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"location that is not permitted"* ]]; then
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r meWATCH:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r meWATCH:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_VTVcab() {
    #未完成。
    local token=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSLI --max-time 10 "https://www.vtvcab.vn/" 2>&1 | grep "token" | grep -Eo 'token=([^;]*)' | tr -d "token=")
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://apigwon.gviet.vn/sdp-vod/api/v1/source" -H "authorization: ${token}" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    echo $result > debug.logs
    if [[ "$result" == *"4006"* ]]; then
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r VTVcab:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r VTVcab:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Vidio() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://geo-id-media-001-vidio-com.akamaized.net/2x2.png" 2>&1)
    if [[ "$result" == "000" ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "000" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Vidio:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_TataPlay() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://watch.tataplay.com/" 2>&1)
    if [[ "$result" == "000" ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "000" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Tata Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_MXPlayer() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://www.mxplayer.in/" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"We are currently not available in your region"* ]]; then
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MXPlayer:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MXPlayer:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_ClipTV() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://cliptv.vn/the-forgiven-2022,lvDoN0JrP/Jx52YAKL2v" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"Sorry, this video is not available in your country."* ]]; then
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Clip TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Clip TV:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_GalaxyPlay() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://api.glxplay.io/account/device/new" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"495"* ]]; then
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Galaxy Play:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_MYTV() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://webapi.mytv.vn/api/v1/movie/138546/play?" -X POST -d "partition=1" 2>&1)
    if [[ "$result" == *"curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep 'result' | awk '{print $2}'| tr -d "," )"
    if [[ "$result1" == "103" ]]; then
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r MYTV:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r MYTV:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Google() {
    local result=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -sSL --max-time 10 "https://www.google.com/async/lbsc" 2>&1)
    if [[ "$result" == *"curl"* ]]; then
        echo -n -e "\r Google Location:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == *"websearch/answer/86640"* ]]; then
        echo -n -e "\r Google Location:\t\t\t${Font_Red}Failed (Unusual Traffic)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | grep "location_address" | python -m json.tool | grep 'location_address' | awk  -F '"' '{print $4}' )"
    if [[ -n "$result1" ]]; then
        echo -n -e "\r Google Location:\t\t\t${Font_Green}$result1${Font_Suffix}\n"
        return
    fi
    echo -n -e "\r Google Location:\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_NHKPlus() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://location-plus.nhk.jp/geoip/area.json" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r NHK+:\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1="$(echo "${result}" | python -m json.tool | grep "country_code" | awk '{print $2}' | cut -d '"' -f 2)"
    if [[ "$result1" == "JP" ]]; then
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r NHK+:\t\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Tiktok() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10  --output /dev/null -w %{url_effective} "https://www.tiktok.com/" 2>&1)
    local result1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 -X POST "https://www.tiktok.com/passport/web/store_region/" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region="$(echo "${result1}" | jq ".data.store_region" | tr -d '"' )"
    if [[ "$result" == *"/explore" ]]; then
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}No  (Region: ${region^^})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Tiktok:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_StarhubTVPlus() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10  --output /dev/null -w %{http_code} "https://ucdn.starhubgo.com/bpk-tv/HubSensasiHD/output/manifest.mpd" 2>&1)
    if [[ "$result" == "curl"* ]] && [[ "$1" == "6" ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}IPv6 Not Support${Font_Suffix}\n"
        return
    elif [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result" == "200" ]]; then
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Eurosport() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSI --max-time 10 "https://www.eurosport.com/" 2>&1)
    # echo ${result: -2}
    if [[ "$result" == "curl"* ]]; then
        echo -n -e "\r Eurosports Region:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local region=$(echo $result | grep eurosport_country_code | grep -Eo "eurosport_country_code=..")
    # if [[ "$result" == "200" ]]; then
    echo -n -e "\r Eurosports Region:\t\t\t${Font_Green}${region: -2}${Font_Suffix}\n"
    #     return
    # else
    #     echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    #     return
    # fi

    # echo -n -e "\r Starhub TV+:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Viaplay() {
    local result1=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sSL --max-time 10 --write-out "%{url_effective}" --output /dev/null "https://viaplay.pl/package?recommended=viaplay" 2>&1)
    local result2=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -sS --max-time 10 --write-out %{redirect_url} --output /dev/null https://viaplay.com/ 2>&1)
    if [[ "$result1" == "curl"* ]] || [[ "$result2" == "curl"* ]]; then
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [[ "$result1" == *"region-blocked"* ]]; then
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        local region=$(echo $result2 | awk -F"/" '{print $4}')
        echo -n -e "\r Viaplay:\t\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Viaplay:\t\t\t\t${Font_Red}Failed${Font_Suffix}\n"
}

function MediaUnlockTest_Sooka() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsL --max-time 10 --write-out %{http_code} --output /dev/null --max-time 10 "https://app-expmanager-proxy.sooka.my/prod/api/v1/enveu_prod/screen?screenId=0" 2>&1)
    if [ "$result" = "000" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    elif [ "$result" = "200" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        return
    elif [ "$result" = "403" ]; then
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    else
        echo -n -e "\r Sooka:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
        return
    fi
}

function MediaUnlockTest_BilibiliAnimeNew() {
    local tmp=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://api.bilibili.com/x/web-interface/zone" 2>&1)
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local country_code=$(echo $tmp | jq '.data.country_code')
    if [ "$country_code" == "86" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region:CN)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "886" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: TW)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "852" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: HK)${Font_Suffix}\n"
        return
    elif [ "$country_code" == "853" ]; then
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Green}Yes (Region: MO)${Font_Suffix}\n"
        return
    else
        local country=$(echo $tmp | jq '.data.country' | tr -d '"' )
        echo -n -e "\r Bilibili Anime:\t\t\t${Font_Red}No${Font_Suffix}  ${Font_Green}(Country: $country)${Font_Suffix}\n"
        return
    fi
}

function echo_Result() {
    for((i=0;i<${#array[@]};i++))
    do
        echo "$result" | grep "${array[i]}"
        # sleep 0.03
    done;
}

if [ -n "$func" ]; then
    echo -e "${Font_Green}IPv4:${Font_Suffix}"
    $func 4
    echo -e "${Font_Green}IPv6:${Font_Suffix}"
    $func 6
    exit
fi

function NA_UnlockTest() {
    echo "===========[ North America ]==========="
    local result=$(
    MediaUnlockTest_Fox ${1} &
    #MediaUnlockTest_HuluUS ${1} &
    MediaUnlockTest_NFLPlus ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_EPIX ${1} &
    MediaUnlockTest_Starz ${1} &
    MediaUnlockTest_Philo ${1} &
    MediaUnlockTest_FXNOW ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_MaxCom ${1} &
    )
    wait
    local array=("FOX:" "Hulu:" "NFL+" "ESPN+:" "Epix:" "Starz:" "Philo:" "FXNOW:" "Max.com")
    echo_Result ${result} ${array}
    MediaUnlockTest_TLCGO ${1}
    echo "$result" | grep "HBO Max:"
    local result=$(
    MediaUnlockTest_Shudder ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_Crackle ${1} &
    MediaUnlockTest_CWTV ${1} &
    MediaUnlockTest_AETV ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_TubiTV ${1} &
    )
    wait
    local array=("Shudder:" "BritBox:" "Crackle:" "CW TV:" "A&E TV:" "NBA TV:")
    echo_Result ${result} ${array}
    MediaUnlockTest_NBCTV ${1}
    echo "$result" | grep "Fubo TV:"
    echo "$result" | grep "Tubi TV:"
    local result=$(
    MediaUnlockTest_SlingTV ${1} &
    MediaUnlockTest_PlutoTV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_encoreTVB ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_DiscoveryPlus ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    MediaUnlockTest_PeacockTV ${1} &
    MediaUnlockTest_Popcornflix ${1} &
    MediaUnlockTest_Crunchyroll ${1} &
    MediaUnlockTest_ATTNOW ${1} &
    MediaUnlockTest_KBSAmerican ${1} &
    MediaUnlockTest_KOCOWA ${1} &
    MediaUnlockTest_MathsSpot ${1} &
    )
    wait
    local array=("Sling TV:" "Pluto TV:" "Acorn TV:" "SHOWTIME:" "encoreTVB:" "Funimation:" "Discovery" "Paramount+:" "Peacock TV:" "Popcornflix:" "Crunchyroll:" "Directv Stream:" "KBS American:" "KOCOWA:" "Maths Spot:")
    echo_Result ${result} ${array}
    ShowRegion CA
    local result=$(
    MediaUnlockTest_CBCGem ${1} &
    MediaUnlockTest_Crave ${1} &
    )
    wait
    echo "$result" | grep "CBC Gem:"
    echo "$result" | grep "Crave:"
    echo "======================================="
}

function EU_UnlockTest() {
    echo "===============[ Europe ]=============="
    local result=$(
    MediaUnlockTest_RakutenTV ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_SkyShowTime ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_MathsSpot ${1} &
    MediaUnlockTest_Eurosport ${1} &
    MediaUnlockTest_Viaplay ${1} &
    # MediaUnlockTest_HBO_Nordic ${1}
    # MediaUnlockTest_HBOGO_EUROPE ${1}
    )
    wait
    local array=("Rakuten TV:" "Funimation:" "SkyShowTime:" "HBO Max:" "Maths Spot:" "Viaplay" "Eurosport" )
    echo_Result ${result} ${array}
    ShowRegion GB
    local result=$(
    MediaUnlockTest_SkyGo ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_ITVHUB ${1} &
    MediaUnlockTest_Channel4 ${1} &
    MediaUnlockTest_Channel5 ${1} &
    MediaUnlockTest_BBCiPLAYER ${1} &
    MediaUnlockTest_DiscoveryPlusUK ${1} &
    )
    wait
    local array=("Sky Go:" "BritBox:" "ITV Hub:" "Channel 4:" "Channel 5" "BBC iPLAYER:" "Discovery+ UK:")
    echo_Result ${result} ${array}
    ShowRegion FR
    local result=$(
    #MediaUnlockTest_Salto ${1} &
    MediaUnlockTest_CanalPlus ${1} &
    MediaUnlockTest_Molotov ${1} &
    MediaUnlockTest_Joyn ${1} &
    MediaUnlockTest_SKY_DE ${1} &
    MediaUnlockTest_ZDF ${1} &
    )
    wait
    local array=("Canal+:" "Molotov:")
    echo_Result ${result} ${array}
    ShowRegion DE
    local array=("Joyn:" "Sky:" "ZDF:")
    echo_Result ${result} ${array}
    ShowRegion NL
    local result=$(
    # MediaUnlockTest_NLZIET ${1} &
    MediaUnlockTest_videoland ${1} &
    MediaUnlockTest_NPO_Start_Plus ${1} &
    # MediaUnlockTest_HBO_Spain ${1}
    # MediaUnlockTest_PANTAYA ${1} &
    MediaUnlockTest_RaiPlay ${1} &
    #MediaUnlockTest_MegogoTV ${1}
    MediaUnlockTest_Amediateka ${1} &
    )
    wait
    local array=("NLZIET:" "videoland:" "NPO Start Plus:")
    echo_Result ${result} ${array}
    # ShowRegion ES
    # echo "$result" | grep "PANTAYA:"
    ShowRegion IT
    echo "$result" | grep "Rai Play:"
    ShowRegion RU
    echo "$result" | grep "Amediateka:"
    echo "======================================="
}

function HK_UnlockTest() {
    echo "=============[ Hong Kong ]============="
       if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
	local result=$(
	    MediaUnlockTest_NowE ${1} &
	    MediaUnlockTest_ViuTV ${1} &
	    MediaUnlockTest_MyTVSuper ${1} &
	    MediaUnlockTest_HBOGO_ASIA ${1} &
	    # MediaUnlockTest_BilibiliHKMCTW ${1} &
	)
    else
	echo -e "${Font_Green}此区域无IPv6可用流媒体，跳过……${Font_Suffix}"
    fi
    wait
    local array=("Now E:" "Viu.TV:" "MyTVSuper:" "HBO GO Asia:" "BiliBili Hongkong/Macau/Taiwan:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function TW_UnlockTest() {
    echo "==============[ Taiwan ]==============="
    local result=$(
    MediaUnlockTest_KKTV ${1} &
    MediaUnlockTest_LiTV ${1} &
    MediaUnlockTest_MyVideo ${1} &
    MediaUnlockTest_4GTV ${1} &
    MediaUnlockTest_LineTV.TW ${1} &
    MediaUnlockTest_HamiVideo ${1} &
    MediaUnlockTest_Catchplay ${1} &
    MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnlockTest_BahamutAnime ${1} &
    #MediaUnlockTest_ElevenSportsTW ${1}
    # MediaUnlockTest_BilibiliTW ${1} &
    )
    wait
    local array=("KKTV:" "LiTV:" "MyVideo:" "4GTV.TV:" "LineTV.TW:" "Hami Video:" "CatchPlay+:" "HBO GO Asia:" "Bahamut Anime:" "Bilibili Taiwan Only:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function JP_UnlockTest() {
    echo "===============[ Japan ]==============="
    local result=$(
    MediaUnlockTest_NHKPlus ${1} &
    MediaUnlockTest_DMMTV ${1} &
    MediaUnlockTest_AbemaTV_IPTest ${1} &
    MediaUnlockTest_Niconico ${1} &
    MediaUnlockTest_music.jp ${1} &
    MediaUnlockTest_Telasa ${1} &
    MediaUnlockTest_Paravi ${1} &
    MediaUnlockTest_unext ${1} &
    MediaUnlockTest_HuluJP ${1} &
    )
    wait
    local array=("NHK+" "DMM TV:" "Abema.TV:" "Niconico:" "music.jp:" "Telasa:" "Paravi:" "U-NEXT:" "Hulu Japan:")
    echo_Result ${result} ${array}
    local result=$(
    MediaUnlockTest_TVer ${1} &
    MediaUnlockTest_wowow ${1} &
    MediaUnlockTest_VideoMarket ${1} &
    MediaUnlockTest_FOD ${1} &
    MediaUnlockTest_Radiko ${1} &
    MediaUnlockTest_DAM ${1} &
    MediaUnlockTest_J:COM_ON_DEMAND ${1} &
    )
    wait
    local array=("TVer:" "WOWOW:" "VideoMarket:" "FOD(Fuji TV):" "Radiko:" "Karaoke@DAM:" "J:com On Demand:")
    echo_Result ${result} ${array}
    ShowRegion Game
    local result=$(
    MediaUnlockTest_Kancolle ${1} &
    MediaUnlockTest_UMAJP ${1} &
    MediaUnlockTest_KonosubaFD ${1} &
    MediaUnlockTest_PCRJP ${1} &
    MediaUnlockTest_WFJP ${1} &
    MediaUnlockTest_ProjectSekai ${1} &
    )
    wait
    local array=("Kancolle Japan:" "Pretty Derby Japan:" "Konosuba Fantastic Days:" "Princess Connect Re:Dive Japan:" "World Flipper Japan:" "Project Sekai: Colorful Stage:")
    echo_Result ${result} ${array}
    echo "======================================="

}

function Global_UnlockTest() {
    echo ""
    echo "============[ Multination ]============"
    if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
        local result=$(
        MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        MediaUnlockTest_PrimeVideo_Region ${1} &
        MediaUnlockTest_TVBAnywhere ${1} &
        MediaUnlockTest_iQYI_Region ${1} &
        MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        #MediaUnlockTest_Instagram.Music ${1}
        GameTest_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        MediaUnlockTest_Tiktok ${1} &
        MediaUnlockTest_BilibiliAnimeNew ${1} &
        )
    else
        local result=$(
        # MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        # MediaUnlockTest_PrimeVideo_Region ${1} &
        # MediaUnlockTest_TVBAnywhere ${1} &
        # MediaUnlockTest_iQYI_Region ${1} &
        # MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        #MediaUnlockTest_Instagram.Music ${1}
        # GameTest_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        )
    fi
    wait
    local array=("Dazn:" "HotStar:" "Disney+:" "Netflix:" "YouTube Premium:" "Amazon Prime Video:" "TVBAnywhere+:" "iQyi Oversea:" "Bilibili Anime:" "Viu.com:" "Tiktok" "YouTube CDN:" "Google" "YouTube Region:" "Netflix Preferred CDN:" "Spotify Registration:" "Steam Currency:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SA_UnlockTest() {
    echo "===========[ South America ]==========="
    local result=$(
    MediaUnlockTest_StarPlus ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_DirecTVGO ${1} &
    MediaUnlockTest_Funimation ${1} &
    )
    wait
    local array=("Star+:" "HBO Max:" "DirecTV Go:" "Funimation:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function OA_UnlockTest() {
    echo "==============[ Oceania ]=============="
    local result=$(
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    )
    wait
    local array=("NBA TV:" "Acorn TV:" "SHOWTIME:" "BritBox:" "Funimation:" "Paramount+:")
    echo_Result ${result} ${array}
    ShowRegion AU
    local result=$(
    MediaUnlockTest_Stan ${1} &
    MediaUnlockTest_Binge ${1} &
    MediaUnlockTest_7plus ${1} &
    MediaUnlockTest_Channel9 ${1} &
    MediaUnlockTest_Channel10 ${1} &
    MediaUnlockTest_ABCiView ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_SBSonDemand ${1} &
    MediaUnlockTest_Docplay ${1}
    MediaUnlockTest_KayoSports ${1}
    )
    wait
    local array=("Stan:" "Binge:" "7plus:" "Channel 9:" "Channel 10:" "ABC iView:" "Docplay:" "Optus Sports:" "SBS on Demand:" "Kayo Sports:")
    echo_Result ${result} ${array}
    ShowRegion NZ
    local result=$(
    MediaUnlockTest_NeonTV ${1} &
    MediaUnlockTest_SkyGONZ ${1} &
    MediaUnlockTest_ThreeNow ${1} &
    MediaUnlockTest_MaoriTV ${1} &
    )
    wait
    local array=("Neon TV:" "SkyGo NZ:" "ThreeNow:" "Maori TV:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function KR_UnlockTest() {
    echo "==============[ Korean ]==============="
    local result=$(
    MediaUnlockTest_Wavve ${1} &
    MediaUnlockTest_Tving ${1} &
    MediaUnlockTest_CoupangPlay ${1} &
    MediaUnlockTest_NaverTV ${1} &
    MediaUnlockTest_Afreeca ${1} &
    MediaUnlockTest_KBSDomestic ${1} &
    #MediaUnlockTest_KOCOWA ${1} &
    )
    wait
    local array=("Wavve:" "Tving:" "Coupang Play:" "Naver TV:" "Afreeca TV:" "KBS Domestic:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SEA_UnlockTest(){
    echo "==========[ SouthEastAsia ]============"
    local result=$(
    MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnblockTest_BGlobalSEA ${1} &
    )
    wait
    local array=("HBO GO Asia:" "B-Global SouthEastAsia:")
    echo_Result ${result} ${array}
    ShowRegion SG
    local result=$(
        MediaUnlockTest_Catchplay ${1} &
        MediaUnlockTest_meWATCH ${1} &
        MediaUnlockTest_StarhubTVPlus ${1} &
    )
    wait
    local array=("meWATCH" "Starhub" "CatchPlay+:")
    echo_Result ${result} ${array}
    ShowRegion TH
    local result=$(
    #MediaUnlockTest_TrueID ${1} &
    MediaUnlockTest_AISPlay ${1} &
    MediaUnblockTest_BGlobalTH ${1} &
    )
    wait
    local array=("TrueID" "AIS Play" "B-Global Thailand Only")
    echo_Result ${result} ${array}
    ShowRegion ID
    local result=$(
    MediaUnlockTest_Vidio ${1} &
    MediaUnblockTest_BGlobalID ${1} &
    )
    wait
    local array=("Vidio" "B-Global Indonesia Only")
    echo_Result ${result} ${array}
    ShowRegion VN
    local result=$(
    # MediaUnlockTest_VTVcab ${1} &
    MediaUnlockTest_MYTV ${1} &
    MediaUnlockTest_ClipTV ${1} &
    MediaUnlockTest_GalaxyPlay ${1} &
    MediaUnblockTest_BGlobalVN ${1} &
    )
    wait
    local array=("MYTV" "Clip TV" "Galaxy Play" "B-Global Việt Nam Only" )
    echo_Result ${result} ${array}
    ShowRegion MY
    local result=$(
    MediaUnlockTest_Sooka ${1} &
    )
    wait
    local array=("Sooka")
    echo_Result ${result} ${array}
    ShowRegion IN
    local result=$(
    MediaUnlockTest_MXPlayer ${1} &
    MediaUnlockTest_TataPlay ${1} &
    )
    wait
    local array=("MXPlayer" "Tata Play" )
    echo_Result ${result} ${array}
    echo "======================================="
}

function Sport_UnlockTest() {
    echo "===============[ Sport ]==============="
    local result=$(
    MediaUnlockTest_Dazn ${1} &
    MediaUnlockTest_StarPlus ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_MolaTV ${1} &
    MediaUnlockTest_SetantaSports ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_BeinConnect ${1} &
    MediaUnlockTest_EurosportRO ${1} &
    )
    wait
    local array=("Dazn:" "Star+:" "ESPN+:" "NBA TV:" "Fubo TV:" "Mola TV:" "Setanta Sports:" "Optus Sports:" "Bein Sports Connect:" "Eurosport RO:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function Openai_UnlockTest() {
    echo "==============[ Openai ]==============="
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chat.openai.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Openai:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result1=$(echo "$tmpresult" | grep 'location' )
    if [ ! -n "$result1" ]; then
    	echo -n -e "\r Openai:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chat.openai.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        echo -n -e "\r Openai:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi

    echo "======================================="
}

function CheckV4() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "${Font_SkyBlue}User Choose to Test Only IPv6 Results, Skipping IPv4 Testing...${Font_Suffix}"
        else
            echo -e " ${Font_SkyBlue}** Checking Results Under IPv4${Font_Suffix} "
            check4=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -4 -s 2>&1)
            echo "--------------------------------"
            echo -e " ${Font_SkyBlue}** Your Network Provider: ${local_isp4} (${local_ipv4_asterisk})${Font_Suffix} "
            if [ -n  "$check4"  ]; then
                isv4=1
            else
                echo -e "${Font_SkyBlue}No IPv4 Connectivity Found, Abort IPv4 Testing...${Font_Suffix}"
                isv4=0
            fi

            echo ""
        fi
    else
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "${Font_SkyBlue}用户选择只检测IPv6结果，跳过IPv4检测...${Font_Suffix}"
        else
            echo -e " ${Font_SkyBlue}** 正在测试IPv4解锁情况${Font_Suffix} "
            check4=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -4 -s 2>&1)
            echo "--------------------------------"
            echo -e " ${Font_SkyBlue}** 您的网络为: ${local_isp4} (${local_ipv4_asterisk})${Font_Suffix} "
            if [ -n  "$check4"  ]; then
                isv4=1
            else
                echo -e "${Font_SkyBlue}当前网络不支持IPv4,跳过...${Font_Suffix}"
                isv4=0
            fi

            echo ""
        fi
    fi
}

function CheckV6() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "${Font_SkyBlue}User Choose to Test Only IPv4 Results, Skipping IPv6 Testing...${Font_Suffix}"
            fi
        else
            check6=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -6 -s 2>&1)
            if [ -n  "$check6"  ]; then
                echo ""
                echo ""
                echo -e " ${Font_SkyBlue}** Checking Results Under IPv6${Font_Suffix} "
                echo "--------------------------------"
                echo -e " ${Font_SkyBlue}** Your Network Provider: ${local_isp6} (${local_ipv6_asterisk})${Font_Suffix} "
                isv6=1
            else
                echo -e "${Font_SkyBlue}No IPv6 Connectivity Found, Abort IPv6 Testing...${Font_Suffix}"
                isv6=0
            fi
            echo -e ""
        fi

    else
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "${Font_SkyBlue}用户选择只检测IPv4结果，跳过IPv6检测...${Font_Suffix}"
            fi
        else
            check6=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -6 -s 2>&1)
            if [ -n  "$check6"  ]; then
                echo ""
                echo ""
                echo -e " ${Font_SkyBlue}** 正在测试IPv6解锁情况${Font_Suffix} "
                echo "--------------------------------"
                echo -e " ${Font_SkyBlue}** 您的网络为: ${local_isp6} (${local_ipv6_asterisk})${Font_Suffix} "
                isv6=1
            else
                echo -e "${Font_SkyBlue}当前主机不支持IPv6,跳过...${Font_Suffix}"
                isv6=0
            fi
            echo -e ""
        fi
    fi
}


function Goodbye() {
    if [[ "$language" == "e" ]]; then
        echo -e "${Font_Green}Testing Done! Thanks for Using This Script! ${Font_Suffix}"
        echo -e ""
        echo -e "${Font_Yellow}Number of Script Runs for Today: ${TodayRunTimes}; Total Number of Script Runs: ${TotalRunTimes} ${Font_Suffix}"
    else
        echo -e "${Font_Green}本次测试已结束，感谢使用此脚本 ${Font_Suffix}"
        echo -e ""
        echo -e "${Font_Yellow}检测脚本当天运行次数: ${TodayRunTimes}; 共计运行次数: ${TotalRunTimes} ${Font_Suffix}"
    fi
}

clear

function ScriptTitle() {
    if [[ "$language" == "e" ]]; then
        echo -e " [Stream Platform & Game Region Restriction Test]"
        echo ""
        echo -e "${Font_Green}Github Repository:${Font_Suffix} ${Font_Yellow} https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
        echo -e "${Font_Purple}Supporting OS: CentOS 6+, Ubuntu 14.04+, Debian 8+, MacOS, Android (Termux), iOS (iSH)${Font_Suffix}"
        echo ""
        echo -e " ** Test Starts At: $(date)"
        echo ""
    else
        echo -e " [流媒体平台及游戏区域限制测试]"
        echo ""
        echo -e "${Font_Green}项目地址${Font_Suffix} ${Font_Yellow}https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
        echo -e "${Font_Green}[商家]TG群组${Font_Suffix} ${Font_Yellow}https://t.me/streamunblock1 ${Font_Suffix}"
        # echo -e "${Font_Purple}脚本适配OS: IDK${Font_Suffix}"
        echo ""
        echo -e " ** 测试时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo ""
    fi
}
ScriptTitle

function Start() {
    if [[ "$language" == "e" ]]; then
        echo -e "${Font_Blue}Please Select Test Region or Press ENTER to Test All Regions${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [1]: [ Multination + Taiwan ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [2]: [ Multination + Hong Kong ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [3]: [ Multination + Japan ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [4]: [ Multination + North America ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [5]: [ Multination + South America ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [6]: [ Multination + Europe ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [7]: [ Multination + Oceania ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [8]: [ Multination + Korean ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [9]: [ Multination + SouthEastAsia ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number [10]: [ OpenAI ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number  [0]: [ Multination Only ]${Font_Suffix}"
        echo -e "${Font_SkyBlue}Input Number [99]: [ Sport Platforms ]${Font_Suffix}"
        read -p "Please Input the Correct Number or Press ENTER:" num
    else
        echo -e "${Font_Blue}请选择检测项目，直接按回车将进行全区域检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [1]: [ 跨国平台+台湾平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [2]: [ 跨国平台+香港平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [3]: [ 跨国平台+日本平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [4]: [ 跨国平台+北美平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [5]: [ 跨国平台+南美平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [6]: [ 跨国平台+欧洲平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [7]: [跨国平台+大洋洲平台]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [8]: [ 跨国平台+韩国平台 ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [9]: [跨国平台+东南亚平台]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字 [10]: [       OpenAI      ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字  [0]: [   只进行跨国平台  ]检测${Font_Suffix}"
        echo -e "${Font_SkyBlue}输入数字 [99]: [   体育直播平台    ]检测${Font_Suffix}"
        read -p "请输入正确数字或直接按回车:" num
    fi
}
Start

function RunScript() {

    if [[ -n "${num}" ]]; then
        if [[ "$num" -eq 1 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                TW_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                TW_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 2 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                HK_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                HK_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 3 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                JP_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                JP_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 4 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                NA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                NA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 5 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 6 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                EU_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                EU_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 7 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                OA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                OA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 8 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                KR_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                KR_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 9 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SEA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SEA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 10 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Openai_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Openai_UnlockTest 6
            fi
            Goodbye


        elif [[ "$num" -eq 99 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Sport_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Sport_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 0 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
            fi
            Goodbye

        else
            echo -e "${Font_Red}请重新执行脚本并输入正确号码${Font_Suffix}"
            echo -e "${Font_Red}Please Re-run the Script with Correct Number Input${Font_Suffix}"
            return
        fi
    else
        clear
        ScriptTitle
        CheckV4
        if [[ "$isv4" -eq 1 ]]; then
            Global_UnlockTest 4
            TW_UnlockTest 4
            HK_UnlockTest 4
            JP_UnlockTest 4
            NA_UnlockTest 4
            SA_UnlockTest 4
            EU_UnlockTest 4
            OA_UnlockTest 4
            KR_UnlockTest 4
        fi
        CheckV6
        if [[ "$isv6" -eq 1 ]]; then
            Global_UnlockTest 6
            TW_UnlockTest 6
            HK_UnlockTest 6
            JP_UnlockTest 6
            NA_UnlockTest 6
            SA_UnlockTest 6
            EU_UnlockTest 6
            OA_UnlockTest 6
            KR_UnlockTest 6
        fi
        Goodbye
    fi
}
wait
RunScript
