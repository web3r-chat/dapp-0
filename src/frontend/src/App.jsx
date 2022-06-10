// eslint-disable-next-line no-use-before-define
import React from 'react'
import { Head } from './common/Head'
import { Footer } from './common/Footer'
import { Navbar } from './common/Navbar'
import { StagingBanner } from './common/StagingBanner'
import { Outlet } from 'react-router-dom'
import { Login } from './routes/Login'
import { WaitAnimation } from './routes/WaitAnimation'

export function App() {
  // Authentication with internet identity
  const [authClient, setAuthClient] = React.useState()
  // JWT for chatbot connection
  const [jwt, setJwt] = React.useState()

  if (!authClient) {
    return (
      <div>
        <Head />
        <Login setAuthClient={setAuthClient} setJwt={setJwt} />
      </div>
    )
  }

  if (jwt === undefined) {
    return (
      <div>
        <Head />
        <WaitAnimation message="Securing chatbot connection with a smart contract" />
      </div>
    )
  }

  return (
    <div>
      <Head />
      {/* <Navbar
        authClient={authClient}
        setAuthClient={setAuthClient}
        jwt={jwt}
        setJwt={setJwt}
      /> */}
      {/* https://stackoverflow.com/a/71882311/5480536 */}
      <Outlet context={[authClient, setAuthClient, jwt, setJwt]} />
      {/* <StagingBanner /> */}
      <Footer />
    </div>
  )
}
