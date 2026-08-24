"""
KBO 기록실 robots.txt 확인 스크립트
- 특정 URL이 크롤링 허용되는지 확인
- User-agent별 Crawl-delay 값을 자동으로 추출
"""

import urllib.robotparser

ROBOTS_URL = "https://www.koreabaseball.com/robots.txt"
TARGET_URL = "https://www.koreabaseball.com/Record/Player/HitterBasic/Basic1.aspx?sort=HRA_RT"

# 실제로 크롤링할 때 사용할 User-Agent (Playwright 요청에도 동일하게 사용)
USER_AGENT = "MyPracticeCrawler/1.0 (+study purpose)"

DEFAULT_DELAY_IF_NONE = 2.0  # robots.txt에 delay 명시가 없을 때 안전하게 쓸 기본 간격(초)


def check_robots(target_url: str, user_agent: str) -> float:
    rp = urllib.robotparser.RobotFileParser()
    rp.set_url(ROBOTS_URL)
    rp.read()

    allowed = rp.can_fetch(user_agent, target_url)
    print(f"[URL] {target_url}")
    print(f"[User-Agent] {user_agent}")
    print(f"[크롤링 허용 여부] {'허용됨 (Allowed)' if allowed else '차단됨 (Disallowed)'}")

    delay = rp.crawl_delay(user_agent)
    if delay is None:
        delay = rp.crawl_delay("*")

    if delay is None:
        print(f"[Crawl-delay] robots.txt에 명시 없음 → 기본값 {DEFAULT_DELAY_IF_NONE}초 사용 예정")
        delay = DEFAULT_DELAY_IF_NONE
    else:
        print(f"[Crawl-delay] robots.txt 명시값: {delay}초")

    if not allowed:
        raise PermissionError("이 URL은 robots.txt에 의해 크롤링이 차단되어 있습니다. 진행하지 마세요.")

    return float(delay)


if __name__ == "__main__":
    delay = check_robots(TARGET_URL, USER_AGENT)
    print(f"\n최종 적용할 요청 간격: {delay}초")