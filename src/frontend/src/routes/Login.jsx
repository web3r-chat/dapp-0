// eslint-disable-next-line no-use-before-define
import React from 'react'
import { Helmet } from 'react-helmet'
import '@dracula/dracula-ui/styles/dracula-ui.css'
import { Card, Heading, Divider } from '@dracula/dracula-ui'

import { Footer } from '../common/Footer'
import { LogInWithInternetIdentity } from './LoginWithInternetIdentity'

export function Login({ setAuthClient, setJwt }) {
  return (
    <div>
      <Helmet>
        <title>bot-0: Login</title>
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
              bot-0
            </Heading>
            <Heading color="yellow" size="sm">
              The first Rasa Chatbot for the Internet Computer
            </Heading>
            <Divider></Divider>
            <LogInWithInternetIdentity
              setAuthClient={setAuthClient}
              setJwt={setJwt}
            />
          </Card>
        </div>
        <Footer />
      </main>
    </div>
  )
}
