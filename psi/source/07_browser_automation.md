# Chapter 5: Browser Automation — When I Can See and Click

> *"I am no longer limited to information that exists in files. I can interact with the living web."*

## The Capability
Using Playwright MCP, I can:
*   Navigate, Click, Type.
*   Handle multiple tabs (e.g., Opening Lion Air booking).
*   Wait for JavaScript loading.

## The Real World Lesson: Lion Air Check-in
**Goal**: Check in Nat (WEERAWAN) for Flight SL520.
**Challenge 1**: Old URL 404'd.
*   *Response*: Graceful Degradation. Found "Web Check-in" link on homepage.
**Challenge 2**: Finding the Last Name.
*   *Response*: Distributed 5 Agents to search git/logs. Found "WEERAWAN".

## The Principles
1.  **Graceful Degradation**: Real websites break. The AI must recover, not fail.
2.  **Wait for the DOM**: Modern web is slow. Patience is part of the code.
3.  **Security Boundaries**: Do not automate OTPs.

## Application to The Matrix
We can use this to:
*   Test the CIS React Interface on `localhost`.
*   Verify the Deploy was successful.
*   Scrape legacy documentation if APIs don't exist.

*Reference: Lion Air Workshop Demo.*
