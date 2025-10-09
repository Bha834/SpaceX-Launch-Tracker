from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route('/')
def index():
    try:
        # Fetch rockets for names
        rockets_response = requests.get('https://api.spacexdata.com/v4/rockets')
        rockets = {r['id']: r['name'] for r in rockets_response.json()}

        # Fetch launchpads for site info
        launchpads_response = requests.get('https://api.spacexdata.com/v4/launchpads')
        launchpads = {lp['id']: {'name': lp['name'], 'locality': lp['locality'], 'region': lp['region']} for lp in launchpads_response.json()}

        response = requests.get('https://api.spacexdata.com/v4/launches')
        launches = response.json()
        # Get last 10 launches
        recent_launches = launches[-10:]

        # Add rocket names and launchpad info
        for launch in recent_launches:
            launch['rocket_name'] = rockets.get(launch.get('rocket'), 'Unknown')
            launch['launchpad_info'] = launchpads.get(launch.get('launchpad'), {})

        # Fetch upcoming launches
        upcoming_response = requests.get('https://api.spacexdata.com/v4/launches?upcoming=true')
        upcoming_launches = upcoming_response.json()

        # Add rocket names and launchpad info to upcoming
        for launch in upcoming_launches:
            launch['rocket_name'] = rockets.get(launch.get('rocket'), 'Unknown')
            launch['launchpad_info'] = launchpads.get(launch.get('launchpad'), {})
        
        # Calculate stats from recent launches
        total_recent = len(recent_launches)
        successful_recent = sum(1 for l in recent_launches if l.get('success'))
        success_rate = (successful_recent / total_recent * 100) if total_recent > 0 else 0
    except:
        recent_launches = []
        upcoming_launches = []
        total_recent = 0
        success_rate = 0
    return render_template('index.html', launches=recent_launches, upcoming=upcoming_launches, total_recent=total_recent, success_rate=success_rate, successful_recent=successful_recent)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
