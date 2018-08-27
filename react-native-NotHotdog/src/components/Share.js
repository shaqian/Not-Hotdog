import React, {Component} from 'react';
import {
  Platform,
  StyleSheet, 
  View, 
  Text,
  TouchableOpacity
} from 'react-native';

import Svg,{
  Text as SvgText
} from 'react-native-svg';

import Share from 'react-native-share';

var RNFS = require('react-native-fs');

class ShareResult extends Component {
  onShare(hotdog) {
    var image = hotdog? 'badgehotdog.jpg': 'badgenothotdog.jpg';

    if (Platform.OS === 'ios') {
      var msg = hotdog? "I got “Hotdog!”": "I got “Not hotdog!”";
      let shareImageBase64 = {
        title: msg,
        message: msg,
        url: "file://" + RNFS.MainBundlePath + '/' + image,
        subject: msg
      };

      Share.open(shareImageBase64);
    } else {
      RNFS.existsAssets(image).then((result) =>{
        if (result)
          RNFS.readFileAssets(image, "base64")
            .then((res) => {
              var msg = hotdog? "I got “Hotdog!”": "I got “Not hotdog!”";
              let shareImageBase64 = {
                title: msg,
                message: msg,
                url: "data:image/jpeg;base64," + res,
                subject: msg
              };

              Share.open(shareImageBase64);
            })
            .catch((error) => console.warn(error));
      });
    }
  }

  render() {
    const {hotdog, onClear} = this.props;
    return (
        <View style={styles.container}>
          <TouchableOpacity style={styles.button} onPress={this.onShare.bind(this, hotdog)}>
            <Text style={styles.text}>Share</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.clearButton} onPress={onClear}>
            <Svg
                height="30"
                width="100"
              >
                <SvgText
                  fill="white"
                  stroke="black"
                  strokeWidth="0.6"
                  fontWeight="bold"
                  fontSize="18"
                  x="50"
                  y="20"
                  textAnchor="middle"
                >
                  No Thanks
                </SvgText> 
              </Svg>
          </TouchableOpacity>
        </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    backgroundColor: 'transparent',
    alignSelf: "center",
    bottom: 0
  },
  button: {
    height: 55,
    width: 200,
    borderColor: "white",
    borderWidth: 2,
    borderRadius: 5,
    alignItems: "center",
    justifyContent: 'center',
    backgroundColor: '#25d5fd',
  },
  text: {
    fontSize: 25,
    fontWeight: "bold",
    color: "white"
  },
  clearButton: {
    height: 60,
    alignItems: "center",
    justifyContent: 'center',
    backgroundColor: 'transparent',
  },
});

export default ShareResult;
