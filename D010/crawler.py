"""
KBO 기록실 크롤러 (Playwright Sync API)
- 팀 타자기록 / 팀 투수기록 / 팀 순위: 표(table) 파싱
- 관중현황: /ws/ 는 robots.txt로 차단되어 있어서 직접 호출하지 않음.
            허용된 페이지(GraphTeam.aspx)를 열고, 그 페이지가 스스로 발생시키는
            네트워크 응답을 옆에서 관찰만 해서 데이터를 얻음.
"""

import time
from playwright.sync_api import sync_playwright

from check_robots import check_robots, USER_AGENT


def parse_team_table(page) -> list[dict]:
    """페이지 내 table.tData 중 '첫 번째' 표만 정확히 집어서 파싱"""
    page.wait_for_selector("table.tData", timeout=10000)

    table = page.locator("table.tData").first

    headers = table.locator("thead th").all_inner_texts()
    headers = [h.strip() for h in headers]

    row_locators = table.locator("tbody tr")
    row_count = row_locators.count()

    records = []
    for i in range(row_count):
        cells = row_locators.nth(i).locator("td").all_inner_texts()
        cells = [c.strip() for c in cells]
        if len(cells) != len(headers):
            continue
        records.append(dict(zip(headers, cells)))

    return records


def crawl_team_urls_sync(urls: list[str]) -> list[list[dict]]:
    """팀 타자/투수/순위 등 표가 있는 페이지들을 순서대로 수집"""
    delay = check_robots(urls[0], USER_AGENT)

    results = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(user_agent=USER_AGENT)
        page = context.new_page()

        for i, url in enumerate(urls):
            print(f"\n[{i+1}/{len(urls)}] 요청: {url}")
            page.goto(url, timeout=15000)
            records = parse_team_table(page)
            results.append(records)
            print(f"  -> {len(records)}행 수집")

            if i < len(urls) - 1:
                print(f"  -> {delay}초 대기 후 다음 요청")
                time.sleep(delay)

        browser.close()

    return results


def fetch_crowd_data_sync(crowd_url: str) -> dict:
    """
    관중현황 페이지(허용된 경로)를 열고, 페이지가 자체적으로 호출하는
    /ws/Record.asmx/GetCrowdTeam 응답을 관찰해서 JSON을 얻는다.
    우리가 /ws/ 를 직접 호출하지 않는다.
    """
    check_robots(crowd_url, USER_AGENT)

    captured = {}

    def handle_response(response):
        if "GetCrowdTeam" in response.url:
            try:
                captured["data"] = response.json()
            except Exception:
                pass

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(user_agent=USER_AGENT)
        page = context.new_page()

        page.on("response", handle_response)
        page.goto(crowd_url, timeout=15000)
        page.wait_for_timeout(3000)

        browser.close()

    if "data" not in captured:
        raise ValueError("관중 데이터 응답을 못 잡았습니다. 대기시간을 늘리거나 URL을 다시 확인하세요.")

    return captured["data"]