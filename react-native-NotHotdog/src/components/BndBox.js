import React, {Component} from 'react';
import {
  StyleSheet, 
  TouchableOpacity
} from 'react-native';

import Svg,{
    Rect,
    Text,
    G
} from 'react-native-svg';

class BndBox extends Component {
  constructor(props) {
    super(props);
    this.state = {
      showBox: false,
      rects: props.rects,
      image: props.image,
    };
  }

  componentWillReceiveProps(nextProps) {
    const {rects, image} = nextProps;
    this.setState({ rects, image});  
  }

  render() {
    const {showBox, rects, image} = this.state;
    return (
      <TouchableOpacity style={styles.container} onPress={() => this.setState({showBox: !showBox})} >
        <Svg
          height={image.h}
          width={image.w}
        >
          {
            showBox && rects && rects.length > 0?
            rects.map((rect, index) => {
              return (
                <G key={index}>
                  <Rect
                    x={rect.x}
                    y={rect.y}
                    width={rect.w}
                    height={rect.h}
                    stroke="#25d5fd"
                    strokeWidth="5"
                    fill="none"
                  />
                  <Text
                    fill="#25d5fd"
                    fontSize="18"
                    fontWeight="bold"
                    x={rect.x + 10}
                    y={rect.y + 20}
                    textAnchor="start"
                  >
                    {(rect.confidence * 100).toFixed(2)}%
                  </Text> 
                </G>
                );
            })
            :undefined
          }
        </Svg>
      </TouchableOpacity>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    top: 0,
    backgroundColor: 'transparent',
    justifyContent: 'center', 
    alignItems: 'center'
  }
});

export default BndBox;
