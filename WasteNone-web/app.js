
// ------------------------------------------------------------ modal ------------------------------------------------------------
  // Get the modal
  const modal = document.getElementById( 'modal' )
  // Get the modal close button 
  const close = document.getElementById( 'close' )
  // Close modal on (x) click 
  close.addEventListener('click',() => { modal.style.display = 'none' })
  // Close modal on click outside
  window.addEventListener('click', event => { 
      if( event.target==modal ){
          modal.style.display = 'none'
      }
  })
// ------------------------------------------------------------ modal ------------------------------------------------------------


// Your web app's Firebase configuration
var firebaseConfig = {
    apiKey: "AIzaSyCHDBgu-lOZJIBmy-I9NAJTl3LOZ8NS9KI",
    authDomain: "wastenone-1bffb.firebaseapp.com",
    databaseURL: "https://wastenone-1bffb.firebaseio.com",
    projectId: "wastenone-1bffb",
    storageBucket: "wastenone-1bffb.appspot.com",
    messagingSenderId: "620456090581",
    appId: "1:620456090581:web:a056f765aad4fb5797bb5c",
    measurementId: "G-G80CY32CM0"
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);


// Auth and storage of Firebase
var auth = firebase.auth()
var storage = firebase.storage()
var database = firebase.database()

// Get OAtuh providers
const oauthProviders = document.getElementById('oauth-providers')

// Get forms for email and pass auth
const createUserForm = document.getElementById('create-user-form')
const logInForm = document.getElementById('log-in-form')
const forgotPasswordForm = document.getElementById('forgot-password-form')

// Get the auth dialogs
const createUserDialog = document.getElementById('create-user-dialog')
const logInDialog = document.getElementById('log-in-dialog')
const haveOrNeedAccountDialog = document.getElementById('have-or-need-account-dialog')
const deleteAccountDialog = document.getElementById('delete-account-dialog')

// Get delete account triggers
const showDeleteAccountDialogTrigger = document.getElementById('show-delete-account-dialog-trigger')
const hideDeleteAccountDialogTrigger = document.getElementById('hide-delete-account-dialog-trigger')

// Get elements to hide or show based on auth state
const hideWhenLoggedIn = document.querySelectorAll('.hide-when-logged-in')
const hideWhenLoggedOut = document.querySelectorAll('.hide-when-logged-out')

// Get email not verified notification element
const emailNotVerifiedNotification = document.getElementById('email-not-verified-notification')

// Access Auth elements to listen on auth actions
const authAction = document.querySelectorAll('.auth')

// Success and error msgs handling
const authMsg = document.getElementById(`message`)


// Get upload input element
const uploadProfilePhotoButton = document.getElementById('upload-profile-photo-button')
// users photo placeholder
const profilePhotoHeader = document.getElementById('profile-photo-header')
const profilePhotoAccount = document.getElementById('profile-photo-account')
// photo upload progres bar
const progressBar = document.getElementById('progress-bar')

// Create new account
showCreateUserForm = () => { 
    hideAuthElements()
    modal.style.display = 'block' 
    oauthProviders.classList.remove(`hide`)
    createUserForm.classList.remove(`hide`)
    logInDialog.classList.remove(`hide`)
    haveOrNeedAccountDialog.classList.remove(`hide`)
}

// Log in
showLogInForm = () => { 
    hideAuthElements()
    modal.style.display = 'block' 
    oauthProviders.classList.remove(`hide`)
    logInForm.classList.remove(`hide`)
    createUserDialog.classList.remove(`hide`)
    haveOrNeedAccountDialog.classList.remove(`hide`)
}

showForgotPasswordForm = () => {
    hideAuthElements()
    forgotPasswordForm.classList.remove(`hide`)
}


hideAuthElements =() =>
{
    clearMsg()
    loading('hide')
    oauthProviders.classList.add(`hide`)
    createUserForm.classList.add(`hide`)
    logInForm.classList.add(`hide`)
    forgotPasswordForm.classList.add(`hide`)
    createUserDialog.classList.add(`hide`)
    logInDialog.classList.add(`hide`)
    haveOrNeedAccountDialog.classList.add(`hide`)
}

// Loop through elements and use the auth attr to determine action
authAction.forEach(eachAction => { 
    eachAction.addEventListener('click', event => { 
        let chosen = event.target.getAttribute('auth')
        if (chosen === 'show-create-user-form') showCreateUserForm()
        else if (chosen === 'show-log-in-form') showLogInForm()
        else if (chosen === 'show-forgot-password-form') showForgotPasswordForm()
        else if (chosen === 'log-out') logOut()
        else if (chosen === 'log-in-with-google') logInWithGoogle()
        else if (chosen === 'log-in-with-twitter') logInWithTwitter()
        else if (chosen === 'log-in-with-github') logInWithGithub()
        else if (chosen === 'show-delete-account-dialog') showDeleteAccountDialog()
        else if (chosen === 'hide-delete-account-dialog') hideDeleteAccountDialog()
        else if (chosen === 'delete-account') deleteAccount()
    })
})


//Log out
logOut = () => {
    auth.signOut()
    clearLocalStorage()
}

// OAuth logins 
logInWithGoogle = () => {
    const googleProvider = new firebase.auth.GoogleAuthProvider()
    logInWithProvider(googleProvider)
}
logInWithTwitter = () => {
    const twitterProvider = new firebase.auth.TwitterAuthProvider()
    logInWithProvider(twitterProvider)
}
logInWithGithub = () => {
    const githubProvider = new firebase.auth.GithubAuthProvider()
    logInWithProvider(githubProvider)
}
logInWithProvider = (provider) => {
    auth.signInWithPopup(provider)
    .then(() => {
        hideAuthElements()
    })
    .catch(error => {
        displayMessage(`error`, error.message)
    })
}

deleteAccount = () => {
    database.ref(`/fridge-list-${uid}`).remove()
    storage.ref('user-profile-photos`').child(uid).delete()
    auth.currentUser.delete()
    .then(() => {
        clearLocalStorage()
        hideAuthElements()
    })
    .catch(error => {
        if( error.code === 'auth/requires-recent-login'){
            auth.signOut()
            .then(() => {
                showLogInForm()
                displayMessage('error', error.message)
            })
        }
    })
}
showDeleteAccountDialog = () =>{ 
    showDeleteAccountDialogTrigger.classList.add(`hide`) 
    deleteAccountDialog.classList.remove(`hide`)
}
hideDeleteAccountDialog = () =>{ 
    showDeleteAccountDialogTrigger.classList.remove(`hide`)
    deleteAccountDialog.classList.add(`hide`) 
}

// UID global. Get the value from the auth state listener
var uid

// Auth state firebase real time monitor
auth.onAuthStateChanged(user => { 
    if (user) {
        //Logged in
        uid = user.uid
        modal.style.display = 'none'

        // users photo OR default pic
        if(user.photoURL){
            profilePhotoHeader.setAttribute('src', user.photoURL)
            profilePhotoAccount.setAttribute('src', user.photoURL)
        }

        //hide or show elements depending on the auth state
        hideWhenLoggedIn.forEach( eachAuthItem => {
            // console.log(eachAuthItem.id + " hide")
            eachAuthItem.classList.add( `hide` )
        })
        hideWhenLoggedOut.forEach( eachAuthItem => {
            // console.log(eachAuthItem.id + " show")
            eachAuthItem.classList.remove( `hide` )
        })

        if( user.displayName )
        {
            document.getElementById('display-name').textContent = `Hello, ${user.displayName}`
        }

        // if local storage has info saying  user is authed by email 
        if( localStorage.getItem('isAuthenticatedWithEmail')){
            if( !user.emailVerified ){
                if( !localStorage.getItem('emailVerificationSent' )){
                    user.sendEmailVerification().then(() =>{
                        localStorage.setItem('emailVerificationSent','true')
                    })
                }
                else{
                    console.log('Verfication email has already be sent')
                }
                emailNotVerifiedNotification.textContent = `Email not verified. Click the link inside the link we sent to ${user.email}`
                emailNotVerifiedNotification.classList.remove('hide')
            }
        }


        // show fridge items based on UID
        database.ref(`/fridge-list-${uid}`).orderByChild(`expiryDate`).on('value', snapshot => {
            snapshot.forEach(data => { console.log(data)})
            document.getElementById('fridge-list-items').innerHTML = ''
            snapshot.forEach(data => {
                let p = document.createElement('p')
                //jQuery:
                p.textContent = data.val().expiryDate + ": " + data.val().item
                let deleteButton = document.createElement('button')
                deleteButton.textContent = 'x'
                deleteButton.classList.add('delete-button')
                deleteButton.setAttribute('data', data.key)
                p.appendChild(deleteButton)
                document.getElementById('fridge-list-items').appendChild(p)
            })
        })
    }
    else{
        // NOT logged in
        console.log('not logged in')

        //hide or show elements depending on the auth state
        hideWhenLoggedIn.forEach( eachAuthItem => {
            eachAuthItem.classList.remove( `hide` )
        })
        hideWhenLoggedOut.forEach( eachAuthItem => {
            eachAuthItem.classList.add( `hide` )
        })
    }})

clearLocalStorage = () => {
    localStorage.removeItem('emailVerificationSent')
    localStorage.removeItem('isAuthenticatedWithEmail')
}

createUserForm.addEventListener('submit', event => {
    event.preventDefault()
    loading('show')
    const displayName = document.getElementById('create-user-display-name').value
    const email = document.getElementById('create-user-email').value
    const password = document.getElementById('create-user-password').value
    auth.createUserWithEmailAndPassword(email,password)
    .then(() => {
        firebase.auth().currentUser.updateProfile({
            displayName: displayName
        })
        createUserForm.reset()
        hideAuthElements();
        //email verification
        localStorage.setItem('isAuthenticatedWithEmail','true')
    })
    .catch(error => { 
        loading('hide')
        displayMessage('error',error.message)
    })
})

logInForm.addEventListener( 'submit', event => {
    event.preventDefault()
    loading('show')
    const email = document.getElementById('log-in-email').value
    const password = document.getElementById('log-in-password').value
    console.log("signing in " + email)
    auth.signInWithEmailAndPassword(email, password)
    .then(() => {
        logInForm.reset()
        hideAuthElements();
        //email verification
        localStorage.setItem('isAuthenticatedWithEmail','true')
    })
    .catch(error => {
        loading('hide')
        displayMessage('error',error.message)
    })
})

forgotPasswordForm.addEventListener('submit', event => {
    event.preventDefault()
    loading('show')
    const email = document.getElementById('forgot-password-email').value
    console.log("reset password for " + email)
    firebase.auth().sendPasswordResetEmail(email)
    .then(() => {
        forgotPasswordForm.reset()
        loading('hide')
        displayMessage('success','Reset password message sent')
    })
    .catch(error => {
        loading('hide')
        displayMessage('error',error.message)
    })
})

// ------------------------------------------------------------ messages ------------------------------------------------------------
// messageTimeout and successTImeout global for clearTimeout to work invoked
let msgTimeout

// error and msg handling
const displayMessage = (type, msg) => {
    if(type === 'error'){
        authMsg.style.borderColor = 'red'
        authMsg.style.color = 'red'
        authMsg.style.display = 'block'
        console.log("error: " + msg)
    }
    else if( type === 'success' ){
        authMsg.style.borderColor = 'green'
        authMsg.style.color = 'green'
        authMsg.style.display = 'block'
        console.log("success: " + msg)
    }    

    authMsg.innerHTML = msg
    msgTimeout = setTimeout(() => {
        authMsg.innerHTML = '';
        authMsg.style.display = 'none'
    }, 7000)
}

clearMsg = () => {
    clearTimeout( msgTimeout )
    authMsg.innerHTML = '';
    authMsg.style.display = 'none'
}
// ------------------------------------------------------------ messages ------------------------------------------------------------

// ---------------------------------------------------------- loading cue -----------------------------------------------------------
// Hide and show visual cue
loading = (action) => {
    if( action === 'show' ){
        document.getElementById('loading-outer-container').style.display = 'block'
    }
    else if( action === 'hide' ){
        document.getElementById('loading-outer-container').style.display = 'none'
    }
    else console.log('loading error')
}
// ---------------------------------------------------------- loading cue -----------------------------------------------------------

// ---------------------------------------------------------- profile photo -----------------------------------------------------------
let photoFile

uploadProfilePhotoButton.addEventListener('change', event =>{
    let file = event.target.files[0]
    const storageRef = storage.ref(`user-profile-photos/${uid}`)
    // progress bar
    const photoUploadTask = storageRef.put(file)
    photoUploadTask.on("state_changed", snapshot => {
        let percentage = snapshot.bytesTransferred / snapshot.totalBytes * 100 
        if( percentage < 10 ){
            progressBar.setAttribute(`style`, `10%`)
            progressBar.innerHTML = `${percentage.toFixed(0)}%`
        }
        else{
            progressBar.setAttribute(`style`, `width: ${percentage}%`)
            progressBar.innerHTML = `${percentage.toFixed(0)}%`
        }
    },
    error = (error) => {
        displayMessage('error', error.message)
    },
    complete = () => {
        photoUploadTask.snapshot.ref.getDownloadURL()
        .then((url) => {
            firebase.auth().currentUser.updateProfile({
                photoURL: url
            })
            .then(() => {
                profilePhotoHeader.setAttribute('src', auth.currentUser.photoURL)
                profilePhotoAccount.setAttribute('src', auth.currentUser.photoURL)
                progressBar.style.width = '0%'
                progressBar.innerHTML = ''
            })
        })
    })
})
// ---------------------------------------------------------- profile photo -----------------------------------------------------------

// ---------------------------------------------------------- fridge list -----------------------------------------------------------
// add
const fridgeListForm = document.getElementById('fridge-list-form')
fridgeListForm.addEventListener('submit', event => {
    event.preventDefault()
    let item = document.getElementById('item').value
    let expiryDate = document.getElementById('expiryDate').value
    // This will create new or add an entity if exists:
    database.ref(`fridge-list-${uid}`).push({
        expiryDate: expiryDate,
        item: item,
        uid: uid
    })
    fridgeListForm.reset()
})

// delete
document.body.addEventListener( 'click', event => {
    if( event.target.matches('.delete-button')){
        key = event.target.getAttribute('data')
        database.ref(`/fridge-list-${uid}`).child(key).remove()
    }
})
// ---------------------------------------------------------- fridge list -----------------------------------------------------------
