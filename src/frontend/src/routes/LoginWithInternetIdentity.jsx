// eslint-disable-next-line no-use-before-define
import React from 'react'
import PropTypes from 'prop-types'

import '@dracula/dracula-ui/styles/dracula-ui.css'
import { Box, Card, Button, Divider, Text } from '@dracula/dracula-ui'

import { AuthClient } from '@dfinity/auth-client'

import { canisterId, createActor } from 'DeclarationsCanisterMotoko'

import { writeAuthClientDetailsToConsole } from './LoginWithInternetIdentityDebug'

const II_URL = process.env.II_URL
const IC_HOST_URL = process.env.IC_HOST_URL
const DJANGO_SERVER_URL = process.env.DJANGO_SERVER_URL

let authClient

export function LogInWithInternetIdentity({ setAuthClient, setJwt }) {
  async function doLogIn() {
    authClient = await AuthClient.create()

    const handleSucess = () => {
      // Save the authClient for use in rest of application
      setAuthClient(authClient)
      //   writeAuthClientDetailsToConsole(authClient)

      // Log into django server
      loginDjangoServer(authClient)
    }

    authClient.login({
      identityProvider: II_URL,
      onSuccess: handleSucess,
    })
  }

  const loginDjangoServer = async (authClient) => {
    await doLoginDjangoServer(authClient)
  }

  async function doLoginDjangoServer(authClient) {
    const identity = await authClient.getIdentity()
    const actor = createActor(canisterId, {
      agentOptions: {
        identity,
        host: IC_HOST_URL,
      },
    })
    try {
      // See the integration test: test/backend/test__login_flow.py

      // Call canister_motoko to create a session password
      const responseCanister = await actor.session_password_create()
      const sessionPassword = responseCanister.ok

      // Ensure django-server is healthy
      const urlHealth = DJANGO_SERVER_URL + '/api/v1/icauth/health'
      const responseHealth = await fetch(urlHealth, {
        method: 'GET',
      })
      if (responseHealth.ok) {
        // console.log('Django server health: ', await responseHealth.json())
      } else {
        throw new Error(
          `Django server health: HTTP error - Status: ${responseHealth.status}`
        )
      }

      // Login to django-server, with username=principal
      // And receive back a JWT token for use with chatbot
      const url = DJANGO_SERVER_URL + '/api/v1/icauth/login'
      const payload = JSON.stringify({
        principal: identity.getPrincipal().toText(),
        session_password: sessionPassword,
      })
      const headers = { 'Content-Type': 'application/json' }
      const responseLogin = await fetch(url, {
        method: 'POST',
        credentials: 'include',
        headers: headers,
        body: payload,
      })
      if (responseLogin.ok) {
        // console.log('Django Login successful')
        const responseLoginJson = await responseLogin.json()
        const jwtToken = responseLoginJson.jwt
        // console.log('jwtToken: ' + jwtToken)

        setJwt(jwtToken)
      } else {
        throw new Error(
          `Django Login failed: HTTP error - Status: ${responseLogin.status}`
        )
      }
    } catch (error) {
      console.error(error)
    }
  }

  return (
    <Box>
      <Card variant="subtle" color="purple" p="md" m="md">
        <Box>
          <Text color="white">Login with your Internet Identity: </Text>
        </Box>

        <Divider></Divider>
        <Button
          variant="ghost"
          color="black"
          size="lg"
          p="2xl"
          onClick={doLogIn}
        >
          <img src="loop.svg" />
        </Button>
      </Card>
    </Box>
  )
}

LogInWithInternetIdentity.propTypes = {
  setAuthClient: PropTypes.func.isRequired,
}
