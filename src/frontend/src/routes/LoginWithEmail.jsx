// eslint-disable-next-line no-use-before-define
import React from 'react'
import PropTypes from 'prop-types'
import '@dracula/dracula-ui/styles/dracula-ui.css'
import {
  Anchor,
  Box,
  Card,
  Heading,
  Button,
  Card,
  Input,
  Divider,
  Text,
} from '@dracula/dracula-ui'

// See: https://www.digitalocean.com/community/tutorials/how-to-add-login-authentication-to-react-applications
async function loginToAuthServer(credentials) {
  return fetch('http://localhost:8081/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(credentials),
  }).then((data) => data.json())
}

export function LoginWithEmail({ setToken }) {
  const [email, setEmail] = React.useState()
  const [password, setPassword] = React.useState()

  const handleSubmit = async (e) => {
    e.preventDefault()
    const token = await loginToAuthServer({
      email,
      password,
    })
    setToken(token)
  }

  return (
    <Card variant="subtle" color="purple" p="md" m="md">
      <Box>
        <Text color="purple">Or... Login with your email instead: </Text>
      </Box>
      <br />
      <div className="login-wrapper">
        <form onSubmit={handleSubmit}>
          <Input
            type="email"
            placeholder="email"
            required
            color="yellow"
            onChange={(e) => setEmail(e.target.value)}
          />
          <br />
          <br />
          <Input
            type="password"
            placeholder="password"
            required
            color="yellow"
            onChange={(e) => setPassword(e.target.value)}
          />
          <br />
          <br />
          <Box>
            <Button
              type="submit"
              variant="ghost"
              color="yellow"
              size="md"
              p="xl"
            >
              Submit
            </Button>
          </Box>
        </form>
      </div>
    </Card>
  )
}

LoginWithEmail.propTypes = {
  setToken: PropTypes.func.isRequired,
}
