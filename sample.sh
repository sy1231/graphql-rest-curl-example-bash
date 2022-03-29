#!/usr/bin/env bash

get_request_body() 
{
cat <<EOF
{
    "id": "$id",
    "name": "$name",
    "json": "$json_str"
}
EOF
}

get_gql_body() 
{
cat <<EOF
{
    "query":
        "query {
            books() {
                count
                records {
                    id
                    name
                    json
                }
            }
        }"
}
EOF
}

resp=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST --data "$(get_gql_body | tr -d '\n\t')" $GQL_URL
    ) 
        
http_code=$(echo $resp | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
content=$(echo $resp | sed -e 's/HTTPSTATUS\:.*//g')

if [ ! $http_code -eq 200 ]; then
    echo "Got http status: $http_code, error: $content"
    exit 1
fi

# iterate over records
for k in $(jq '.books.records | keys | .[]' <<< "$content"); do
    id=$(jq -r ".books.records[$k].id" <<< "$content")
    name=$(jq -r ".books.records[$k].name" <<< "$content")
    
    json=$(jq -r ".books.records[$k].json" <<< "$content")
    json_str=$(jq @json <<< "$json")
  
    status_code=$(curl -s -w %{http_code} --output /dev/null \
        -H "Content-Type:application/json" \
        -X POST --data "$(get_request_body)" "$REST_URL"
        )
    
    if [ ! $status_code -eq 200 ] ; then
        echo "Failed to post book data. Status Code: ${status_code}"
    fi
done