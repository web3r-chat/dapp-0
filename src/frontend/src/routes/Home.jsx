// eslint-disable-next-line no-use-before-define
import React from 'react'
import { Helmet } from 'react-helmet'
import { useOutletContext } from 'react-router-dom'
import '@dracula/dracula-ui/styles/dracula-ui.css'
import { Box, Card, Divider, Heading, Text } from '@dracula/dracula-ui'
import { Bot0 } from '../common/Bot0'

export function Home() {
  const [authClient, setAuthClient, jwt, setJwt] = useOutletContext()

  const identity = authClient.getIdentity()
  const principal = identity.getPrincipal()
  //   console.log('principal  : ' + principal)
  return (
    <div>
      <Helmet>
        <title>bot-0: Home</title>
      </Helmet>
      <main>
        <div className="container-fluid text-center">
          <Card
            variant="subtle"
            color="none"
            my="sm"
            p="sm"
            display="inline-block"
          >
            <Heading color="white" size="xl">
              Hello!
            </Heading>
            <Text color="yellow" size="xs">
              {principal.toString()}
            </Text>
            <Divider></Divider>
            <Card variant="subtle" color="purple" p="md" m="md">
              <Box>
                <Text color="white">
                  Please click below to chat with bot-0.
                </Text>
              </Box>
            </Card>
          </Card>
        </div>
      </main>
      <Bot0 jwt={jwt}></Bot0>
    </div>
  )
}
