#This project automates saving the Discover Weekly playlist using the Spotify API.

# Importing Modules 
import spotipy
import time
from spotipy.oauth2 import SpotifyOAuth

from flask import Flask, request, url_for, session, redirect 

# Initializing Flask App 
app = Flask(__name__)

# Set the name of the session cookie & a random secret key to sign in the cookie 
app.config['Session_Cookie_Name'] = 'Spotify Cookie'
app.secret_key = 'Your Secret Key'

# Set the key for the token info in the session dictionary
TOKEN_INFO = 'token_info'

# Route to handle logging in
@app.route('/')
def login():
    # Creating a SpotifyOAuth instance and get the authorization URL
    auth_url = create_spotify_oauth().get_authorize_url()
    # Redirect user to authorization link 
    return redirect(auth_url)

# Route to handle the redirect URI after authorization
@app.route('/redirect')
def redirect_page():
    # Clear the session
    session.clear()
    # Get the authorization code from the request parameters 
    code = request.args.get('code')
    # Exchange authorization code for an access token and refresh token 
    token_info = create_spotify_oauth().get_access_token(code)
    # Save token info in session 
    session[TOKEN_INFO] = token_info
    # Redirect the user to the save_discover_weekly_route 
    return redirect(url_for('save_discover_weekly', _external =True)) 

# Route to save the Discover Weekly songs to a playlist 
@app.route('/saveDiscoverWeekly')
def save_discover_weekly(): 

    try:
        # Get token info from session 
        token_info = get_token()
    except: 
        # If token info not found, redirect user to login route 
        print("User not logged in")
        return redirect('/')
    
    # Create Spotipy instance with the access token 
    sp = spotipy.Spotify(auth=token_info['access_token'])
    user_id = sp.current_user()['id']

    # Gets user's playlists
    current_playlists =  sp.current_user_playlists()['items']
    discover_weekly_playlist_id = None
    saved_weekly_playlist_id = None

    # Find the Discover Weekly and Saved Weekly Playlists 
    for playlist in current_playlists:
        if(playlist['name'] == 'Discover Weekly'):
            discover_weekly_playlist_id = playlist['id']
        if(playlist['name'] == 'Saved Weekly'):
            saved_weekly_playlist_id = playlist['id']
    
    # If Discover Weekly playlist isn't found, return an error messsage 
    if not discover_weekly_playlist_id:
        return 'Discover Weekly not found.'
    
    # If Saved Weekly playlist isn't found, create a new playlist 
    if not saved_weekly_playlist_id:
        new_playlist = sp.user_playlist_create(user_id, 'Saved Weekly', True)
        saved_weekly_playlist_id = new_playlist['id']

    # Get tracks from Discover Weekly playlist     
    discover_weekly_playlist = sp.playlist_items(discover_weekly_playlist_id)
    song_uris = []
    for song in discover_weekly_playlist['items']:
        song_uri= song['track']['uri']
        song_uris.append(song_uri)
    
    # Add the tracks to the Saved Weekly playlist 
    sp.user_playlist_add_tracks("YOUR_USER_ID", saved_weekly_playlist_id, song_uris, None)

   # Return a success message 
    return ('Discover Weekly songs added successfully')

# Function to get the token info from session
def get_token():
    token_info = session.get(TOKEN_INFO, None)
    if not token_info:
        # If the token info is not found, redirect the user to the login route
        redirect(url_for('login', _external=False))
    
    # Check if the token is expired and refresh if necessary 
    now = int(time.time())

    
    is_expired = token_info['expires_at'] - now < 60
    if(is_expired):
        spotify_oauth = create_spotify_oauth()
        token_info = spotify_oauth.refresh_access_token(token_info['refresh_token'])

    return token_info

def create_spotify_oauth():
    return SpotifyOAuth(
        client_id = "client id",
        client_secret = "client secret",
        redirect_uri = url_for('redirect_page', _external=True),
        scope = 'user-library-read playlist-modify-public playlist-modify-private'
    )

app.run(debug=True)
