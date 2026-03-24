---
name: tokyo-exhibitions
description: >
  Search for current and upcoming museum, art gallery, and exhibition hall exhibitions near a location
  (default: Tokyo Station, 20km radius) during specified travel dates. Use this skill whenever the user
  asks about exhibitions, art shows, museum exhibits, gallery events, or 展覽/美術館/博物館 near their
  travel destination. Trigger phrases include "東京展覽", "展覽", "美術館", "博物館", "what exhibitions",
  "art shows near", "museum exhibits". Also trigger when the user mentions wanting cultural activities
  or things to see/do at their destination during specific dates.
---

# Tokyo Exhibitions Skill

Search for museum, art gallery, and exhibition hall exhibitions near a location during travel dates,
and output a bilingual (日本語 / 繁體中文) markdown file.

## How it works

Use **WebSearch** and **WebFetch** to find exhibitions at major museums and galleries within 20km of
the specified location (default: Tokyo Station). The search covers the user's travel date range.

## Step 1: Determine parameters

Extract from the user's message:

- **Center location**: Default is 東京駅 (Tokyo Station). The user may specify another station or area.
- **Radius**: Fixed at 20km.
- **Date range**: The travel dates (e.g., 04/16–04/21). If not specified, check the project's itinerary
  markdown for dates.

## Step 2: Broad keyword search

Run multiple WebSearch queries in parallel to cover different venue types and sources. Search in Japanese
for best results. Example queries:

```
東京 美術館 展覧会 {year}年{month}月
東京 博物館 企画展 {year}年{month}月
東京 ギャラリー 展示 {year}年{month}月
上野 美術館 展覧会 {year}年{month}月
六本木 美術館 展覧会 {year}年{month}月
```

Also search aggregator sites that list multiple exhibitions:
```
tokyoartbeat.com 東京 展覧会 {year}年{month}月
fashion-press.net 東京 展覧会 {year}年{month}月
```

## Step 3: Venue-by-venue verification (critical!)

Broad keyword searches only surface "headline" exhibitions and miss companion exhibitions at the same
venue (e.g., 国立西洋美術館 running both a European art show AND a Hokusai prints show on a shared
ticket). To avoid this, **visit each major venue's official exhibition page** via WebFetch.

### Must-check venue list

| Area | Venue | Exhibition page URL |
|------|-------|-------------------|
| 上野 | 東京国立博物館 | https://www.tnm.jp/modules/r_free_page/index.php?id=1255 |
| 上野 | 国立西洋美術館 | https://www.nmwa.go.jp/jp/exhibitions/upcoming.html |
| 上野 | 東京都美術館 | https://www.tobikan.jp/exhibition/ |
| 上野 | 上野の森美術館 | https://www.ueno-mori.org/exhibitions/ |
| 六本木 | 国立新美術館 | https://www.nact.jp/exhibition_special/ |
| 六本木 | 森美術館 | https://www.mori.art.museum/jp/exhibitions/ |
| 六本木 | 森アーツセンターギャラリー | https://macg.roppongihills.com/jp/exhibitions/ |
| 六本木 | サントリー美術館 | https://www.suntory.co.jp/sma/exhibition/ |
| 六本木 | 21_21 DESIGN SIGHT | https://www.2121designsight.jp/program/ |
| 六本木 | 泉屋博古館東京 | https://sen-oku.or.jp/tokyo/program_t/ |
| 丸の内/京橋 | 三菱一号館美術館 | https://mimt.jp/exhibition/ |
| 丸の内 | 東京ステーションギャラリー | https://www.ejrcf.or.jp/gallery/exhibition.html |
| 京橋 | アーティゾン美術館 | https://www.artizon.museum/exhibition/ |
| 竹橋 | 東京国立近代美術館 | https://www.momat.go.jp/exhibitions |
| 南青山 | 根津美術館 | https://www.nezu-muse.or.jp/jp/exhibition/index.html |
| 初台 | 東京オペラシティ アートギャラリー | https://www.operacity.jp/ag/ |
| 新宿 | SOMPO美術館 | https://www.sompo-museum.org/exhibitions/ |
| 清澄白河 | 東京都現代美術館 | https://www.mot-art-museum.jp/exhibitions/ |
| 恵比寿 | 東京都写真美術館 | https://topmuseum.jp/ |
| 白金台 | 東京都庭園美術館 | https://www.teien-art-museum.ne.jp/exhibition/ |
| 豊洲 | チームラボプラネッツ | https://www.teamlab.art/e/planets/ |

For each venue, check ALL exhibitions listed — not just the main one. A single venue often has 2-3
concurrent exhibitions (sometimes on a shared ticket), and missing these is the most common failure mode.

Also check which venues are temporarily closed for renovation (休館中). Note this in the output so the
user doesn't plan a visit to a closed museum.

## Step 4: Compile results

For each confirmed exhibition running during the travel dates, collect:

| Field | Description |
|-------|-------------|
| 展覽名稱 / Exhibition Name | Japanese name + Chinese translation |
| 場館 / Venue | Japanese name + Chinese translation |
| 地址 / Address | Japanese address |
| 展期 / Dates | Full exhibition period (YYYY/MM/DD – YYYY/MM/DD) |
| 票價 / Admission | Adult price (note any discounts, shared tickets, free categories) |
| 簡介 / Description | 1-2 sentence summary in 繁體中文 |
| 官網 / Website | Official exhibition or venue URL |
| 注意事項 | Reservation required? Closed days during travel? Opens mid-trip? |

## Step 5: Output markdown file

Save to the project directory as `{location}_exhibitions_{date_range}.md`.
Example filename: `tokyo_exhibitions_0416-0421.md`

### Output template

```markdown
# 🎨 {Location} 展覽情報 / {Location} Exhibition Guide

> 📅 旅行日期 / Travel Dates: {start_date} – {end_date}
> 📍 搜尋範圍 / Search Area: {location} 方圓 20km

---

## 🏛️ {Area Name} 地區

### {Exhibition Name Japanese}
**{Exhibition Name Chinese}**

- 🏛️ 場館 / Venue: {Venue Japanese} ({Venue Chinese})
- 📍 地址 / Address: {Address}
- 📅 展期 / Dates: {Start} – {End}
- 🎫 票價 / Admission: {Price}
- 📝 {Description in 繁體中文}
- 🔗 {URL}
- 💡 / ⚠️ {Tips or warnings if applicable}

---

(repeat for each exhibition, grouped by area)

## 📌 實用資訊 / Practical Tips

- 🎫 **GRUTTO PASS（ぐるっとパス）** — ¥2,500 for ~100 facilities
- 🗓️ Most museums closed on **Mondays**. Flag which Monday(s) fall in the travel dates.
- 🕐 Last entry typically **30 minutes before closing**
- 🌙 Friday/Saturday many museums open until **20:00**
- 🚇 Suggest area-based itinerary groupings (which museums are walkable from each other)
- 💰 Price ranking from cheapest to most expensive
- 🎓 Flag any free-for-students deals
```

## Important notes

- The venue-by-venue check (Step 3) is the most important step — never skip it. Broad searches alone
  will miss 30-40% of exhibitions, especially companion shows on shared tickets.
- Always verify dates against official sources — search snippets often show outdated info
- Group exhibitions by geographic area so the user can plan visits efficiently
- Flag exhibitions that require advance reservation (予約制 / 日時指定予約制)
- Note regular closing days (休館日) that fall within the travel dates
- Note venues closed for renovation (休館中 / 改修工事中)
- Include permanent exhibitions only if noteworthy (e.g., チームラボ)
- When two exhibitions share a ticket, clearly note this to help the user save money
