// eslint-disable-next-line no-use-before-define
import React from 'react'
import { Helmet } from 'react-helmet'

import '@dracula/dracula-ui/styles/dracula-ui.css'

const BOT_0_URL = process.env.BOT_0_URL

export function Bot0({ jwt }) {
  React.useEffect(() => {
    return function cleanup() {
      console.log(
        'Cleaning up the div rasa-chat-widget-container in Bot0 useEffect'
      )
      const d = document.getElementById('rasa-chat-widget-container')
      document.body.removeChild(d)
    }
  })
  const initialPayload =
    '/connect' +
    JSON.stringify({
      jwt: jwt,
    })
  //   console.log('bot-0, BOT_0_URL = ', BOT_0_URL)
  //   console.log('bot-0, initialPayload = ', initialPayload)
  return (
    <div>
      <Helmet>
        <title>bot-0: Home</title>
        {/* <link rel="stylesheet" type="text/css" href="rasa-chat-style.css" /> */}
        <script
          src="https://unpkg.com/@rasahq/rasa-chat@0.1.2/dist/widget.js"
          type="application/javascript"
        ></script>
      </Helmet>
      <div
        id="rasa-chat-widget"
        data-websocket-url={BOT_0_URL}
        data-avatar-url="https://docs.google.com/drawings/d/e/2PACX-1vT-tOoa5MOwggr4dw-aARw0h1WUKbDd4yrFj51EY-iwwGpN-gg94P1UCGn5IFIrzV67bD9K_zILvEpQ/pub?w=360&amp;h=360"
        data-avatar-background="hsl(230, 15%, 30%)"
        data-default-open="false"
        data-font=""
        data-height="400"
        data-width="300"
        data-initial-payload={initialPayload}
        data-primary="hsl(250, 100%, 75%)"
        data-primary-highlight="hsl(250, 100%, 75%)"
        data-token={jwt}
      ></div>
    </div>
  )
}
