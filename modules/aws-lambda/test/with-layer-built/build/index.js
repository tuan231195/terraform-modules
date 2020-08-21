const { get } = require('lodash');

exports.handler = async function(event, context) {
    return get({ message: 'OK' }, 'message');
}