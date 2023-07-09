
/*
 
// https://www.youtube.com/watch?v=ig5-4F9OmbM&t=422s

const functions = require('firebase-functions');
const algoliasearch = require('algoliasearch');
const admin = require('firebase-admin');
admin.initializeApp();

const ALGOLIA_APP_ID =  'SKJIA8T5Z2' // functions.config().algolia.app_id
const ALGOLIA_ADMIN_KEY = 'cde90e9470f0ee7676b7c06fbd200132' // functions.config().algolia.api_key
// const ALGOLIA_SEARCH_KEY = functions.config().algolia.search_key
const ALGOLIA_INDEX_NAME = 'songs'

functions.config()
const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const index = client.initIndex(ALGOLIA_INDEX_NAME);

exports.addToIndex = functions.firestore
    .document('songs/{songId}')
    .onCreate((snap, context) => {
        const data = snap.data();
        data.objectID = context.params.songId // snap.id;
        return index.saveObject(data); //{ ...data, objectID }
    });

exports.updateIndex = functions.firestore
    .document('songs/{songId}')
    .onUpdate((change, context) => {
        const data = change.after.data();
        data.objectID = context.params.songId // change.after.id;
        return index.saveObject(data);
    });

exports.deleteFromIndex = functions.firestore.document('songs/{songId}')
    .onDelete((snap, context) =>
        index.deleteObject(context.params.songId) // snap.id
    );

const indexUsers = client.initIndex('users');

exports.addToIndexUsers = functions.firestore
    .document('users/{id}')
    .onCreate((snap, context) => {
        const data = snap.data();
        data.objectID = context.params.id // snap.id;
        return indexUsers.saveObject(data); //{ ...data, objectID }
    });

exports.updateIndexUsers = functions.firestore
    .document('users/{id}')
    .onUpdate((change, context) => {
        const data = change.after.data();
        data.objectID = context.params.id // change.after.id;
        return indexUsers.saveObject(data);
    });

exports.deleteFromIndexUsers = functions.firestore.document('users/{id}')
    .onDelete((snap, context) =>
        indexUsers.deleteObject(context.params.id) // snap.id
    );
    
*/
