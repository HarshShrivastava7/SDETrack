#!/bin/bash

# Define the health check URLs for your MongoDB servers
MONGO_SERVERS=(
    "mongodb://shard1_r1:27017"
    "mongodb://shard2_r1:27017"
    "mongodb://cfg_r1:27017"
    # "mongodb://router1:27017"
)

# Function to check MongoDB health
check_mongo_health() {
    for server in "${MONGO_SERVERS[@]}"; do
        echo "Checking health for MongoDB server: $server"
        # Check if the server is reachable and responsive
        if !  /usr/bin/mongosh "$server" --eval 'db.adminCommand("ping")' --quiet; then
            echo "MongoDB server $server is not healthy. Waiting..."
            return 1
        fi
    done
    echo "All MongoDB servers are healthy."
    return 0
}

# Wait until all MongoDB servers are healthy
until check_mongo_health; do
    sleep 10  # Check every 10 seconds
done

# Run initialization commands after confirming MongoDB is healthy
echo "All MongoDB servers are healthy. Running initialization commands..."


 /usr/bin/mongosh --host shard1_r1 --port 27017 <<EOF
    rs.initiate({
    _id: "shard1",
    members: [
        {_id: 0, host: "shard1_r1:27017"},
    ],
    settings: {
      electionTimeoutMillis: 2000
    }});
EOF

 /usr/bin/mongosh --host shard2_r1 --port 27017 <<EOF
    rs.initiate({
    _id: "shard2",
    members: [
        {_id: 0, host: "shard2_r1:27017"},
    ],
    settings: {
      electionTimeoutMillis: 2000
    }});
EOF

 /usr/bin/mongosh --host cfg_r1 --port 27017 <<EOF
    rs.initiate({
    _id: "cfg",
    members: [
        {_id: 0, host: "cfg_r1:27017"},
    ],
    settings: {
      electionTimeoutMillis: 2000
    }});
EOF